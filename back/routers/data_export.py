# backend/routers/data_export.py

from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import StreamingResponse, FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta
from typing import Optional
import csv
import io
import os
import tempfile
import json

from database import get_db
import models
from slowapi import Limiter
from slowapi.util import get_remote_address

router = APIRouter(prefix="/api/export", tags=["Data Export"])
limiter = Limiter(key_func=get_remote_address)


def _get_user_data(db: Session, user_id: int, days: int = 30):
    """جمع جميع بيانات المستخدم للتصدير"""
    start_date = datetime.now() - timedelta(days=days)

    water = (
        db.query(models.WaterIntake)
        .filter(
            models.WaterIntake.user_id == user_id,
            models.WaterIntake.date_time >= start_date,
        )
        .order_by(models.WaterIntake.date_time)
        .all()
    )

    user_nutrition = (
        db.query(models.UserNutrition)
        .filter(models.UserNutrition.user_id == user_id)
        .first()
    )

    weight_history = []
    if user_nutrition:
        weight_history = (
            db.query(models.WeightHistory)
            .filter(
                models.WeightHistory.user_nutrition_id == user_nutrition.id,
                models.WeightHistory.date >= start_date,
            )
            .order_by(models.WeightHistory.date)
            .all()
        )

    symptoms = (
        db.query(models.Symptom)
        .filter(
            models.Symptom.user_id == user_id, models.Symptom.date_time >= start_date
        )
        .order_by(models.Symptom.date_time)
        .all()
    )

    meals = (
        db.query(models.Meal)
        .filter(models.Meal.user_id == user_id, models.Meal.date_time >= start_date)
        .order_by(models.Meal.date_time)
        .all()
    )

    walking = (
        db.query(models.WalkingActivity)
        .filter(
            models.WalkingActivity.user_id == user_id,
            models.WalkingActivity.date >= start_date,
        )
        .order_by(models.WalkingActivity.date)
        .all()
    )

    medications = (
        db.query(models.Medication).filter(models.Medication.user_id == user_id).all()
    )

    doses = (
        db.query(models.MedicationDose)
        .filter(
            models.MedicationDose.user_id == user_id,
            models.MedicationDose.scheduled_time >= start_date,
        )
        .order_by(models.MedicationDose.scheduled_time)
        .all()
    )

    quiz_sessions = (
        db.query(models.DailyQuizSession)
        .filter(
            models.DailyQuizSession.user_id == user_id,
            models.DailyQuizSession.date >= start_date,
        )
        .order_by(models.DailyQuizSession.date)
        .all()
    )

    return {
        "water": water,
        "weight": weight_history,
        "symptoms": symptoms,
        "meals": meals,
        "walking": walking,
        "medications": medications,
        "doses": doses,
        "quiz": quiz_sessions,
    }


@router.get("/csv/{user_id}")
@limiter.limit("10/minute")
def export_csv(
    request: Request, user_id: int, days: int = 30, db: Session = Depends(get_db)
):
    """تصدير البيانات كملف CSV"""
    data = _get_user_data(db, user_id, days)

    output = io.StringIO()
    writer = csv.writer(output)

    # === Water ===
    writer.writerow(["=== WATER INTAKE ==="])
    writer.writerow(["Date", "Amount (L)", "Time"])
    for w in data["water"]:
        writer.writerow(
            [
                w.date_time.strftime("%Y-%m-%d"),
                f"{w.amount:.2f}",
                w.date_time.strftime("%H:%M"),
            ]
        )
    writer.writerow([])

    # === Weight ===
    writer.writerow(["=== WEIGHT HISTORY ==="])
    writer.writerow(["Date", "Weight (kg)"])
    for w in data["weight"]:
        writer.writerow([w.date.strftime("%Y-%m-%d"), f"{w.weight:.1f}"])
    writer.writerow([])

    # === Symptoms ===
    writer.writerow(["=== SYMPTOMS ==="])
    writer.writerow(["Date", "Symptom", "Severity", "Notes"])
    for s in data["symptoms"]:
        writer.writerow(
            [s.date_time.strftime("%Y-%m-%d %H:%M"), s.name, s.severity, s.notes or ""]
        )
    writer.writerow([])

    # === Meals ===
    writer.writerow(["=== MEALS ==="])
    writer.writerow(
        ["Date", "Meal Type", "Calories", "Protein (g)", "Carbs (g)", "Fat (g)"]
    )
    for m in data["meals"]:
        writer.writerow(
            [
                m.date_time.strftime("%Y-%m-%d %H:%M"),
                m.meal_type or "",
                m.total_calories or 0,
                m.total_protein or 0,
                m.total_carbs or 0,
                m.total_fat or 0,
            ]
        )
    writer.writerow([])

    # === Walking ===
    writer.writerow(["=== WALKING ACTIVITY ==="])
    writer.writerow(["Date", "Steps", "Distance (km)", "Calories"])
    for w in data["walking"]:
        writer.writerow(
            [
                w.date.strftime("%Y-%m-%d"),
                w.steps,
                (
                    f"{w.distance_km:.2f}"
                    if hasattr(w, "distance_km") and w.distance_km
                    else ""
                ),
                w.calories_burned or 0,
            ]
        )
    writer.writerow([])

    # === Medication Doses ===
    writer.writerow(["=== MEDICATION DOSES ==="])
    writer.writerow(["Date", "Medication", "Status"])
    for d in data["doses"]:
        med_name = ""
        if d.medication and d.medication.medicine:
            med_name = d.medication.medicine.name_ar
        writer.writerow(
            [d.scheduled_time.strftime("%Y-%m-%d %H:%M"), med_name, d.status]
        )
    writer.writerow([])

    # === Quiz ===
    writer.writerow(["=== DAILY QUIZ ==="])
    writer.writerow(["Date", "Morning Score", "Evening Score", "Sleep Hours", "Mood"])
    for q in data["quiz"]:
        writer.writerow(
            [
                q.date.strftime("%Y-%m-%d"),
                q.morning_score or "",
                q.evening_score or "",
                q.sleep_hours or "",
                q.mood or "",
            ]
        )

    output.seek(0)
    filename = f"health_data_user_{user_id}_{datetime.now().strftime('%Y%m%d')}.csv"

    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={
            "Content-Disposition": f"attachment; filename={filename}",
            "Content-Type": "text/csv; charset=utf-8",
        },
    )


@router.get("/json/{user_id}")
@limiter.limit("10/minute")
def export_json(
    request: Request, user_id: int, days: int = 30, db: Session = Depends(get_db)
):
    """تصدير البيانات كملف JSON"""
    data = _get_user_data(db, user_id, days)

    export_data = {
        "export_date": datetime.now().isoformat(),
        "user_id": user_id,
        "period_days": days,
        "water_intake": [
            {"date": w.date_time.isoformat(), "amount_liters": w.amount}
            for w in data["water"]
        ],
        "weight_history": [
            {"date": w.date.isoformat(), "weight_kg": w.weight} for w in data["weight"]
        ],
        "symptoms": [
            {
                "date": s.date_time.isoformat(),
                "name": s.name,
                "severity": s.severity,
                "notes": s.notes,
            }
            for s in data["symptoms"]
        ],
        "meals": [
            {
                "date": m.date_time.isoformat(),
                "type": m.meal_type,
                "calories": m.total_calories,
                "protein_g": m.total_protein,
                "carbs_g": m.total_carbs,
                "fat_g": m.total_fat,
            }
            for m in data["meals"]
        ],
        "walking": [
            {
                "date": w.date.isoformat(),
                "steps": w.steps,
                "calories_burned": w.calories_burned,
            }
            for w in data["walking"]
        ],
        "medication_doses": [
            {"date": d.scheduled_time.isoformat(), "status": d.status}
            for d in data["doses"]
        ],
        "daily_quiz": [
            {
                "date": q.date.isoformat(),
                "morning_score": q.morning_score,
                "evening_score": q.evening_score,
                "sleep_hours": q.sleep_hours,
                "mood": q.mood,
            }
            for q in data["quiz"]
        ],
    }

    filename = f"health_data_user_{user_id}_{datetime.now().strftime('%Y%m%d')}.json"

    return StreamingResponse(
        iter([json.dumps(export_data, ensure_ascii=False, indent=2)]),
        media_type="application/json",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("/pdf/{user_id}")
@limiter.limit("5/minute")
def export_pdf(
    request: Request, user_id: int, days: int = 30, db: Session = Depends(get_db)
):
    """تصدير تقرير PDF شامل"""
    data = _get_user_data(db, user_id, days)

    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.lib import colors
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.platypus import (
            SimpleDocTemplate,
            Paragraph,
            Spacer,
            Table,
            TableStyle,
            PageBreak,
            HRFlowable,
        )
        from reportlab.pdfbase import pdfmetrics
        from reportlab.pdfbase.ttfonts import TTFont
    except ImportError:
        raise HTTPException(
            status_code=500,
            detail="PDF generation library not installed. Run: pip install reportlab",
        )

    # Create temp file
    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp:
        filename = tmp.name

    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        rightMargin=30,
        leftMargin=30,
        topMargin=30,
        bottomMargin=30,
    )

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "CustomTitle",
        parent=styles["Heading1"],
        fontSize=20,
        spaceAfter=20,
        alignment=1,  # Center
    )
    heading_style = ParagraphStyle(
        "CustomHeading",
        parent=styles["Heading2"],
        fontSize=14,
        spaceBefore=15,
        spaceAfter=10,
        textColor=colors.HexColor("#1565C0"),
    )
    normal_style = ParagraphStyle(
        "CustomNormal", parent=styles["Normal"], fontSize=10, spaceAfter=6
    )

    elements = []

    # Title
    elements.append(Paragraph("📊 Health Report - VITA", title_style))
    elements.append(
        Paragraph(
            f"Period: Last {days} days | Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
            normal_style,
        )
    )
    elements.append(Spacer(1, 20))
    elements.append(
        HRFlowable(width="100%", thickness=1, color=colors.HexColor("#1565C0"))
    )
    elements.append(Spacer(1, 20))

    # Water Section
    elements.append(Paragraph("💧 Water Intake", heading_style))
    if data["water"]:
        water_data = [["Date", "Amount (L)"]]
        for w in data["water"][-30:]:
            water_data.append([w.date_time.strftime("%Y-%m-%d"), f"{w.amount:.2f}"])
        total_water = sum(w.amount for w in data["water"])
        water_data.append(["TOTAL", f"{total_water:.2f}"])

        t = Table(water_data, colWidths=[150, 100])
        t.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1565C0")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("FONTSIZE", (0, 0), (-1, -1), 10),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                    ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#E3F2FD")),
                ]
            )
        )
        elements.append(t)
    else:
        elements.append(Paragraph("No water intake data recorded.", normal_style))
    elements.append(Spacer(1, 15))

    # Weight Section
    elements.append(Paragraph("⚖️ Weight History", heading_style))
    if data["weight"]:
        weight_data = [["Date", "Weight (kg)"]]
        for w in data["weight"][-30:]:
            weight_data.append([w.date.strftime("%Y-%m-%d"), f"{w.weight:.1f}"])
        t = Table(weight_data, colWidths=[150, 100])
        t.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#00897B")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("FONTSIZE", (0, 0), (-1, -1), 10),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ]
            )
        )
        elements.append(t)
    else:
        elements.append(Paragraph("No weight data recorded.", normal_style))
    elements.append(Spacer(1, 15))

    # Symptoms Section
    elements.append(Paragraph("🤒 Symptoms", heading_style))
    if data["symptoms"]:
        symptom_data = [["Date", "Symptom", "Severity"]]
        for s in data["symptoms"][-30:]:
            symptom_data.append([s.date_time.strftime("%Y-%m-%d"), s.name, s.severity])
        t = Table(symptom_data, colWidths=[100, 150, 80])
        t.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E65100")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("FONTSIZE", (0, 0), (-1, -1), 9),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ]
            )
        )
        elements.append(t)
    else:
        elements.append(Paragraph("No symptoms recorded.", normal_style))
    elements.append(Spacer(1, 15))

    # Walking Section
    elements.append(Paragraph("🚶 Walking Activity", heading_style))
    if data["walking"]:
        walk_data = [["Date", "Steps", "Calories"]]
        for w in data["walking"][-30:]:
            walk_data.append(
                [w.date.strftime("%Y-%m-%d"), str(w.steps), str(w.calories_burned or 0)]
            )
        total_steps = sum(w.steps for w in data["walking"])
        walk_data.append(["TOTAL", str(total_steps), ""])

        t = Table(walk_data, colWidths=[100, 80, 80])
        t.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2E7D32")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("FONTSIZE", (0, 0), (-1, -1), 10),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ]
            )
        )
        elements.append(t)
    else:
        elements.append(Paragraph("No walking data recorded.", normal_style))
    elements.append(Spacer(1, 15))

    # Medication Section
    elements.append(Paragraph("💊 Medication Adherence", heading_style))
    if data["doses"]:
        med_data = [["Date", "Status"]]
        for d in data["doses"][-30:]:
            med_data.append([d.scheduled_time.strftime("%Y-%m-%d %H:%M"), d.status])
        t = Table(med_data, colWidths=[150, 100])
        t.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#6A1B9A")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                    ("FONTSIZE", (0, 0), (-1, -1), 10),
                    ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ]
            )
        )
        elements.append(t)
    else:
        elements.append(Paragraph("No medication data recorded.", normal_style))

    # Build PDF
    doc.build(elements)

    return FileResponse(
        filename,
        media_type="application/pdf",
        filename=f"health_report_user_{user_id}_{datetime.now().strftime('%Y%m%d')}.pdf",
    )


@router.get("/available/{user_id}")
@limiter.limit("30/minute")
def get_export_info(
    request: Request, user_id: int, days: int = 30, db: Session = Depends(get_db)
):
    """معلومات عن البيانات المتاحة للتصدير"""
    data = _get_user_data(db, user_id, days)

    return {
        "success": True,
        "user_id": user_id,
        "period_days": days,
        "available_formats": ["csv", "json", "pdf"],
        "data_summary": {
            "water_records": len(data["water"]),
            "weight_records": len(data["weight"]),
            "symptom_records": len(data["symptoms"]),
            "meal_records": len(data["meals"]),
            "walking_records": len(data["walking"]),
            "medication_doses": len(data["doses"]),
            "quiz_sessions": len(data["quiz"]),
        },
        "export_endpoints": {
            "csv": f"/api/export/csv/{user_id}?days={days}",
            "json": f"/api/export/json/{user_id}?days={days}",
            "pdf": f"/api/export/pdf/{user_id}?days={days}",
        },
    }
