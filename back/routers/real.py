# routers/real_estate.py

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import Optional, List, Dict, Any
from datetime import datetime, date, timedelta
from pydantic import BaseModel, Field
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
import joblib
import json

from database import get_db
import models
from routers.auth import get_current_user

router = APIRouter(prefix="/real-estate", tags=["Real Estate"])

# ========== Pydantic Models ==========


class PropertyBase(BaseModel):
    link: Optional[str] = None
    title: Optional[str] = None
    property_type: Optional[str] = None
    price: float
    location: str
    state: Optional[str] = None
    area: float
    bedrooms: Optional[int] = None
    bathrooms: Optional[int] = None
    down_payment: Optional[float] = 0
    payment_method: str = "Cash"
    source: str = "bayut"
    description: Optional[str] = None
    features: Optional[str] = None


class PropertyCreate(PropertyBase):
    pass


class PropertyResponse(PropertyBase):
    id: int
    price_per_m: Optional[float] = None
    buy_score: Optional[float] = None
    value_score: Optional[float] = None
    investment_score: Optional[float] = None
    scrape_date: datetime
    is_active: bool

    class Config:
        from_attributes = True


class PropertySearchFilters(BaseModel):
    state: Optional[str] = None
    location: Optional[str] = None
    property_type: Optional[str] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    min_area: Optional[float] = None
    max_area: Optional[float] = None
    bedrooms: Optional[int] = None
    bathrooms: Optional[int] = None
    payment_method: Optional[str] = None
    min_buy_score: Optional[float] = None
    max_buy_score: Optional[float] = None
    sort_by: Optional[str] = "price_asc"
    limit: int = 100
    offset: int = 0


class PredictionRequest(BaseModel):
    area: float
    bedrooms: int = 3
    bathrooms: int = 2
    location: str
    property_type: str = "Apartment"
    payment_method: str = "Cash"


class PredictionResponse(BaseModel):
    predicted_price: float
    predicted_price_per_m: float
    confidence_lower: float
    confidence_upper: float
    area_intelligence_score: float
    recommendation: str


class AreaIntelligenceResponse(BaseModel):
    area_name: str
    state: str
    area_score: int
    investment_potential: float
    resale_liquidity: float
    schools_quality: float
    services_level: float
    transportation: float
    near_sea: bool
    category: str
    key_insights: str


class MarketInsightsResponse(BaseModel):
    total_properties: int
    avg_price: float
    avg_price_per_m: float
    price_range: Dict[str, float]
    top_locations: List[Dict]
    property_type_distribution: List[Dict]
    payment_method_distribution: List[Dict]
    price_trend: Dict
    last_update: datetime


class PropertyAlertCreate(BaseModel):
    alert_name: str
    location: Optional[str] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    min_area: Optional[float] = None
    max_area: Optional[float] = None
    bedrooms: Optional[int] = None
    property_type: Optional[str] = None


# ========== Helper Functions ==========


def calculate_buy_score(property_data: dict, area_data: dict = None) -> float:
    """حساب Buy Score للعقار"""
    try:
        price_score = 0.5
        area_score = 0.5
        if area_data:
            area_score = area_data.get("area_score", 70) / 100

        investment_score = (
            area_data.get("investment_potential", 3) / 5 if area_data else 0.6
        )

        buy_score = (
            price_score * 0.30 + area_score * 0.35 + investment_score * 0.35
        ) * 100

        return round(min(max(buy_score, 0), 100), 2)

    except Exception as e:
        print(f"Error calculating buy score: {e}")
        return 50.0


def calculate_price_per_m(price: float, area: float) -> float:
    """حساب سعر المتر"""
    if area and area > 0:
        return round(price / area, 2)
    return 0


# ========== API Endpoints ==========


@router.get("/properties", response_model=Dict[str, Any])
async def get_properties(
    state: Optional[str] = Query(None, description="Filter by state/city"),
    location: Optional[str] = Query(None, description="Filter by location"),
    min_price: Optional[float] = Query(None, description="Minimum price"),
    max_price: Optional[float] = Query(None, description="Maximum price"),
    min_area: Optional[float] = Query(None, description="Minimum area"),
    max_area: Optional[float] = Query(None, description="Maximum area"),
    bedrooms: Optional[int] = Query(None, description="Number of bedrooms"),
    property_type: Optional[str] = Query(None, description="Property type"),
    limit: int = Query(50000, ge=1, le=100000),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """الحصول على قائمة العقارات مع فلاتر"""

    query = db.query(models.Property).filter(models.Property.is_active == True)

    if state:
        query = query.filter(models.Property.state == state)
    if location:
        query = query.filter(models.Property.location.ilike(f"%{location}%"))
    if min_price:
        query = query.filter(models.Property.price >= min_price)
    if max_price:
        query = query.filter(models.Property.price <= max_price)
    if min_area:
        query = query.filter(models.Property.area >= min_area)
    if max_area:
        query = query.filter(models.Property.area <= max_area)
    if bedrooms:
        query = query.filter(models.Property.bedrooms == bedrooms)
    if property_type:
        query = query.filter(models.Property.property_type == property_type)

    total = query.count()
    properties = query.offset(offset).limit(limit).all()

    # Convert ORM objects to dicts for serialization
    properties_list = []
    for p in properties:
        prop_dict = {
            "id": p.id,
            "link": p.link,
            "title": p.title,
            "property_type": p.property_type,
            "price": float(p.price) if p.price else 0,
            "location": p.location,
            "state": p.state,
            "area": float(p.area) if p.area else 0,
            "bedrooms": p.bedrooms,
            "bathrooms": p.bathrooms,
            "down_payment": float(p.down_payment) if p.down_payment else 0,
            "payment_method": p.payment_method.value if p.payment_method else "Cash",
            "price_per_m": float(p.price_per_m) if p.price_per_m else 0,
            "source": p.source,
            "buy_score": float(p.buy_score) if p.buy_score else 0,
            "value_score": float(p.value_score) if p.value_score else 0,
            "investment_score": float(p.investment_score) if p.investment_score else 0,
            "scrape_date": p.scrape_date.isoformat() if p.scrape_date else None,
            "is_active": p.is_active,
            "description": p.description,
            "features": p.features,
        }
        properties_list.append(prop_dict)

    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "properties": properties_list,
    }


@router.get("/properties/{property_id}", response_model=PropertyResponse)
async def get_property(property_id: int, db: Session = Depends(get_db)):
    """الحصول على تفاصيل عقار محدد"""
    property = (
        db.query(models.Property).filter(models.Property.id == property_id).first()
    )
    if not property:
        raise HTTPException(status_code=404, detail="Property not found")
    return property


@router.post("/properties", response_model=PropertyResponse)
async def create_property(
    property_data: PropertyCreate,
    db: Session = Depends(get_db),
):
    """إضافة عقار جديد"""
    price_per_m = calculate_price_per_m(property_data.price, property_data.area)

    area_intelligence = (
        db.query(models.AreaIntelligence)
        .filter(models.AreaIntelligence.area_name.ilike(f"%{property_data.location}%"))
        .first()
    )

    buy_score = calculate_buy_score(
        property_data.dict(), area_intelligence.__dict__ if area_intelligence else None
    )

    db_property = models.Property(
        **property_data.dict(),
        price_per_m=price_per_m,
        buy_score=buy_score,
        user_id=None,
    )

    db.add(db_property)
    db.commit()
    db.refresh(db_property)

    return db_property


@router.post("/properties/batch")
async def create_properties_batch(
    batch_data: dict,
    db: Session = Depends(get_db),
):
    """إضافة عدة عقارات دفعة واحدة"""
    properties_data = batch_data.get("properties", [])

    if not properties_data:
        raise HTTPException(status_code=400, detail="No properties provided")

    added = 0
    failed = 0
    errors = []

    for prop_data in properties_data:
        try:
            price_per_m = calculate_price_per_m(
                prop_data.get("price", 0), prop_data.get("area", 0)
            )

            area_intelligence = (
                db.query(models.AreaIntelligence)
                .filter(
                    models.AreaIntelligence.area_name.ilike(
                        f"%{prop_data.get('location', '')}%"
                    )
                )
                .first()
            )

            buy_score = calculate_buy_score(
                prop_data, area_intelligence.__dict__ if area_intelligence else None
            )

            # التحقق من وجود البيانات المطلوبة
            if (
                not prop_data.get("price")
                or not prop_data.get("area")
                or not prop_data.get("location")
            ):
                failed += 1
                errors.append(
                    {
                        "property": prop_data.get("link"),
                        "error": "Missing required fields",
                    }
                )
                continue

            db_property = models.Property(
                link=prop_data.get("link"),
                title=prop_data.get("title"),
                property_type=prop_data.get("property_type"),
                price=prop_data.get("price"),
                location=prop_data.get("location"),
                state=prop_data.get("state"),
                area=prop_data.get("area"),
                bedrooms=prop_data.get("bedrooms", 2),
                bathrooms=prop_data.get("bathrooms", 1),
                down_payment=prop_data.get("down_payment", 0),
                payment_method=prop_data.get("payment_method", "Cash"),
                source=prop_data.get("source", "bayut"),
                scrape_date=prop_data.get("scrape_date", datetime.now()),
                price_per_m=price_per_m,
                buy_score=buy_score,
                user_id=None,
                is_active=True,
            )

            db.add(db_property)
            added += 1

        except Exception as e:
            failed += 1
            errors.append({"property": prop_data.get("link"), "error": str(e)})

    try:
        db.commit()
        print(f"✅ تم إضافة {added} عقار بنجاح")
    except Exception as e:
        db.rollback()
        print(f"❌ خطأ في حفظ البيانات: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    return {
        "added": added,
        "failed": failed,
        "total": len(properties_data),
        "errors": errors[:10],
    }


@router.put("/properties/{property_id}")
async def update_property(
    property_id: int,
    property_data: PropertyCreate,
    db: Session = Depends(get_db),
):
    """تحديث بيانات عقار"""
    property = (
        db.query(models.Property).filter(models.Property.id == property_id).first()
    )
    if not property:
        raise HTTPException(status_code=404, detail="Property not found")

    for key, value in property_data.dict().items():
        setattr(property, key, value)

    property.price_per_m = calculate_price_per_m(property.price, property.area)

    area_intelligence = (
        db.query(models.AreaIntelligence)
        .filter(models.AreaIntelligence.area_name.ilike(f"%{property.location}%"))
        .first()
    )

    property.buy_score = calculate_buy_score(
        property.__dict__, area_intelligence.__dict__ if area_intelligence else None
    )

    db.commit()
    return {"message": "Property updated successfully"}


@router.delete("/properties/{property_id}")
async def delete_property(
    property_id: int,
    db: Session = Depends(get_db),
):
    """حذف عقار (Soft delete)"""
    property = (
        db.query(models.Property).filter(models.Property.id == property_id).first()
    )
    if not property:
        raise HTTPException(status_code=404, detail="Property not found")

    property.is_active = False
    db.commit()
    return {"message": "Property deleted successfully"}


@router.post("/predict", response_model=PredictionResponse)
async def predict_price(request: PredictionRequest, db: Session = Depends(get_db)):
    """توقع سعر عقار بناءً على المواصفات"""

    area_intelligence = (
        db.query(models.AreaIntelligence)
        .filter(models.AreaIntelligence.area_name.ilike(f"%{request.location}%"))
        .first()
    )

    avg_price_per_m = (
        db.query(func.avg(models.Property.price_per_m))
        .filter(
            models.Property.location.ilike(f"%{request.location}%"),
            models.Property.is_active == True,
        )
        .scalar()
    )

    if not avg_price_per_m:
        avg_price_per_m = (
            db.query(func.avg(models.Property.price_per_m)).scalar() or 15000
        )

    area_multiplier = 1.0
    if area_intelligence:
        area_multiplier = 1 + ((area_intelligence.area_score - 50) / 100)

    # Convert Decimal from MySQL to float for arithmetic
    avg_price_per_m = float(avg_price_per_m) if avg_price_per_m else 0.0

    predicted_price_per_m = avg_price_per_m * area_multiplier
    predicted_price = predicted_price_per_m * request.area
    confidence_interval = predicted_price * 0.15

    area_score = area_intelligence.area_score if area_intelligence else 70
    if area_score >= 80:
        recommendation = "ممتاز - منطقة استثمارية واعدة 🟢"
    elif area_score >= 65:
        recommendation = "جيد - فرصة استثمارية مناسبة 🟡"
    elif area_score >= 50:
        recommendation = "متوسط - يحتاج إلى دراسة 🟠"
    else:
        recommendation = "منطقة عالية المخاطر - يُفضل التأني 🔴"

    return PredictionResponse(
        predicted_price=round(predicted_price, 2),
        predicted_price_per_m=round(predicted_price_per_m, 2),
        confidence_lower=round(predicted_price - confidence_interval, 2),
        confidence_upper=round(predicted_price + confidence_interval, 2),
        area_intelligence_score=area_score,
        recommendation=recommendation,
    )


@router.get("/insights/market", response_model=MarketInsightsResponse)
async def get_market_insights(db: Session = Depends(get_db)):
    """الحصول على رؤى وتحليلات السوق"""

    total_properties = (
        db.query(models.Property).filter(models.Property.is_active == True).count()
    )
    avg_price = (
        db.query(func.avg(models.Property.price))
        .filter(models.Property.is_active == True)
        .scalar()
        or 0
    )
    avg_price_per_m = (
        db.query(func.avg(models.Property.price_per_m))
        .filter(models.Property.is_active == True)
        .scalar()
        or 0
    )
    min_price = (
        db.query(func.min(models.Property.price))
        .filter(models.Property.is_active == True)
        .scalar()
        or 0
    )
    max_price = (
        db.query(func.max(models.Property.price))
        .filter(models.Property.is_active == True)
        .scalar()
        or 0
    )

    top_locations = (
        db.query(
            models.Property.location,
            func.count(models.Property.id).label("count"),
            func.avg(models.Property.price_per_m).label("avg_price_per_m"),
        )
        .filter(models.Property.is_active == True)
        .group_by(models.Property.location)
        .order_by(func.count(models.Property.id).desc())
        .limit(10)
        .all()
    )

    property_type_dist = (
        db.query(
            models.Property.property_type, func.count(models.Property.id).label("count")
        )
        .filter(models.Property.is_active == True)
        .group_by(models.Property.property_type)
        .all()
    )

    payment_method_dist = (
        db.query(
            models.Property.payment_method,
            func.count(models.Property.id).label("count"),
        )
        .filter(models.Property.is_active == True)
        .group_by(models.Property.payment_method)
        .all()
    )

    last_30_days = datetime.now() - timedelta(days=30)
    price_trend_data = (
        db.query(
            func.date(models.Property.scrape_date).label("date"),
            func.avg(models.Property.price_per_m).label("avg_price"),
        )
        .filter(
            models.Property.scrape_date >= last_30_days,
            models.Property.is_active == True,
        )
        .group_by(func.date(models.Property.scrape_date))
        .order_by("date")
        .all()
    )

    price_trend = {
        "data": [
            {"date": str(d.date), "avg_price": float(d.avg_price)}
            for d in price_trend_data
        ],
        "change_percent": 0,
    }

    if len(price_trend_data) >= 2:
        first_price = float(price_trend_data[0].avg_price)
        last_price = float(price_trend_data[-1].avg_price)
        if first_price > 0:
            price_trend["change_percent"] = round(
                ((last_price - first_price) / first_price) * 100, 2
            )

    last_update = (
        db.query(func.max(models.Property.scrape_date)).scalar() or datetime.now()
    )

    return MarketInsightsResponse(
        total_properties=total_properties,
        avg_price=round(float(avg_price), 2),
        avg_price_per_m=round(float(avg_price_per_m), 2),
        price_range={"min": float(min_price), "max": float(max_price)},
        top_locations=[
            {
                "location": l.location,
                "count": l.count,
                "avg_price_per_m": round(l.avg_price_per_m, 2),
            }
            for l in top_locations
        ],
        property_type_distribution=[
            {"type": p.property_type or "Unknown", "count": p.count}
            for p in property_type_dist
        ],
        payment_method_distribution=[
            {"method": p.payment_method, "count": p.count} for p in payment_method_dist
        ],
        price_trend=price_trend,
        last_update=last_update,
    )


@router.get("/recommendations")
async def get_recommendations(
    budget: Optional[float] = Query(None, description="Your budget"),
    location: Optional[str] = Query(None, description="Preferred location"),
    bedrooms: Optional[int] = Query(None, description="Number of bedrooms"),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
):
    """توصيات شراء مخصصة"""

    query = db.query(models.Property).filter(models.Property.is_active == True)

    if budget:
        query = query.filter(models.Property.price <= budget)
    if location:
        query = query.filter(models.Property.location.ilike(f"%{location}%"))
    if bedrooms:
        query = query.filter(models.Property.bedrooms == bedrooms)

    recommendations = (
        query.order_by(
            models.Property.buy_score.desc(), models.Property.price_per_m.asc()
        )
        .limit(limit)
        .all()
    )

    return {
        "count": len(recommendations),
        "recommendations": recommendations,
        "note": "يتم ترتيب التوصيات بناءً على Buy Score (كلما زاد كان أفضل)",
    }


@router.get("/area-intelligence/{area_name}", response_model=AreaIntelligenceResponse)
async def get_area_intelligence(area_name: str, db: Session = Depends(get_db)):
    """الحصول على تفاصيل ذكاء منطقة محددة"""
    area = (
        db.query(models.AreaIntelligence)
        .filter(models.AreaIntelligence.area_name.ilike(f"%{area_name}%"))
        .first()
    )
    if not area:
        raise HTTPException(status_code=404, detail=f"Area '{area_name}' not found")
    return area


@router.get("/area-intelligence", response_model=List[AreaIntelligenceResponse])
async def get_all_areas(db: Session = Depends(get_db)):
    """الحصول على جميع بيانات ذكاء المناطق"""
    areas = db.query(models.AreaIntelligence).all()
    return areas


@router.post("/area-intelligence")
async def create_or_update_area_intelligence(
    area_data: dict,
    db: Session = Depends(get_db),
):
    """إضافة أو تحديث ذكاء منطقة"""

    existing = (
        db.query(models.AreaIntelligence)
        .filter(models.AreaIntelligence.area_name == area_data.get("area_name"))
        .first()
    )

    if existing:
        for key, value in area_data.items():
            setattr(existing, key, value)
    else:
        new_area = models.AreaIntelligence(**area_data)
        db.add(new_area)

    db.commit()
    return {"message": "Area intelligence saved successfully"}


@router.get("/compare")
async def compare_properties(
    property_ids: str = Query(..., description="Comma-separated property IDs"),
    db: Session = Depends(get_db),
):
    """مقارنة بين عدة عقارات"""

    ids = [int(x.strip()) for x in property_ids.split(",")]
    properties = db.query(models.Property).filter(models.Property.id.in_(ids)).all()

    if len(properties) < 2:
        raise HTTPException(
            status_code=400, detail="At least 2 properties required for comparison"
        )

    comparison = {
        "properties": [
            {
                "id": p.id,
                "title": p.title,
                "price": p.price,
                "price_per_m": p.price_per_m,
                "area": p.area,
                "bedrooms": p.bedrooms,
                "bathrooms": p.bathrooms,
                "location": p.location,
                "payment_method": p.payment_method,
                "buy_score": p.buy_score,
                "link": p.link,
            }
            for p in properties
        ],
        "best_value": (
            min(
                properties,
                key=lambda x: x.price_per_m if x.price_per_m else float("inf"),
            ).id
            if properties
            else None
        ),
        "best_score": (
            max(properties, key=lambda x: x.buy_score or 0).id if properties else None
        ),
        "cheapest": min(properties, key=lambda x: x.price).id if properties else None,
    }

    return comparison


@router.get("/stats/summary")
async def get_stats_summary(db: Session = Depends(get_db)):
    """ملخص إحصائي سريع للوحة التحكم"""

    total = db.query(models.Property).filter(models.Property.is_active == True).count()
    avg_price = (
        db.query(func.avg(models.Property.price))
        .filter(models.Property.is_active == True)
        .scalar()
        or 0
    )
    avg_area = (
        db.query(func.avg(models.Property.area))
        .filter(models.Property.is_active == True)
        .scalar()
        or 0
    )

    top_area = (
        db.query(
            models.Property.location,
            func.avg(models.Property.buy_score).label("avg_score"),
        )
        .filter(models.Property.is_active == True)
        .group_by(models.Property.location)
        .order_by(func.avg(models.Property.buy_score).desc())
        .first()
    )

    recent_count = (
        db.query(models.Property)
        .filter(models.Property.scrape_date >= datetime.now() - timedelta(days=7))
        .count()
    )

    return {
        "total_properties": total,
        "average_price": round(float(avg_price), 2),
        "average_area": round(float(avg_area), 2),
        "best_buy_area": top_area.location if top_area else "N/A",
        "best_buy_score": round(float(top_area.avg_score), 2) if top_area else 0,
        "new_this_week": recent_count,
        "last_updated": datetime.now().isoformat(),
    }
