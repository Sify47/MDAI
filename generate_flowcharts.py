import os
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = r"e:\Flutter\hospital\New folder"

def get_font(size=14, bold=False):
    """Try to get a font, fallback to default"""
    candidates = [
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/ARIALBD.TTF" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/consola.ttf",
        "C:/Windows/Fonts/msgothic.ttc",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except:
                continue
    return ImageFont.load_default()

def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def draw_rounded_box(draw, xy, fill, outline=None, radius=8):
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=1 if outline else 0)

def wrap_text(text, font, max_width, draw):
    words = text.split()
    lines = []
    current_line = ""
    for w in words:
        test = current_line + (" " if current_line else "") + w
        bbox = draw.textbbox((0, 0), test, font=font)
        w_px = bbox[2] - bbox[0]
        if w_px > max_width and current_line:
            lines.append(current_line)
            current_line = w
        else:
            current_line = test
    if current_line:
        lines.append(current_line)
    return lines

def draw_centered_text(draw, text, font, cx, cy, fill):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((cx - tw//2, cy - th//2), text, fill=fill, font=font)

def draw_box_with_text(draw, x, y, w, h, text, fill, text_color, font, radius=8):
    draw_rounded_box(draw, (x, y, x+w, y+h), fill=fill, radius=radius)
    lines = wrap_text(text, font, w-12, draw)
    total_th = len(lines) * (font.size + 4)
    start_y = y + (h - total_th)//2
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        lw = bbox[2] - bbox[0]
        draw.text((x + (w - lw)//2, start_y), line, fill=text_color, font=font)
        start_y += font.size + 4

def draw_arrow(draw, x1, y1, x2, y2, color="#64748b", width=2):
    draw.line([(x1, y1), (x2, y2)], fill=color, width=width)
    arr_size = 8
    dx = x2 - x1
    dy = y2 - y1
    length = (dx*dx + dy*dy)**0.5
    if length == 0:
        return
    ux, uy = dx/length, dy/length
    px, py = ux*arr_size, uy*arr_size
    cx, cy = x2 - px, y2 - py
    perp_x, perp_y = -uy*arr_size*0.5, ux*arr_size*0.5
    pts = [(x2, y2), (cx + perp_x, cy + perp_y), (cx - perp_x, cy - perp_y)]
    draw.polygon(pts, fill=color)

def draw_arrow_down(draw, x, y_bottom, y_next_top, color="#64748b", width=2):
    draw_arrow(draw, x, y_bottom, x, y_next_top, color, width)

def draw_subtitle(draw, x, y, w, text, color="#94a3b8", font=None):
    if font is None:
        font = get_font(11)
    draw_centered_text(draw, text, font, x + w//2, y, color)

# ============================================================
# FLOWCHART 1: System Architecture Overview
# ============================================================
def create_architecture_overview():
    W, H = 1200, 800
    img = Image.new("RGB", (W, H), "#0f172a")
    draw = ImageDraw.Draw(img)

    title_font = get_font(22, bold=True)
    subtitle_font = get_font(12)
    box_font = get_font(13)
    small_font = get_font(11)

    # Title
    draw_centered_text(draw, "🏗️ System Architecture Overview", title_font, W//2, 30, "#f8fafc")
    draw_centered_text(draw, "HealthMate - Flutter + FastAPI + MySQL", subtitle_font, W//2, 58, "#94a3b8")

    # Layers
    layers = [
        ("Flutter Frontend (Dart)", 50, 80, 1100, 150, "#1e3a5f", [
            "Screens: NutritionDashboard, AIInsightsScreen, ServicesScreen",
            "MealPlannerScreen, AddMealScreen, MealSuggestionsScreen",
            "Widgets: AiRecommendationCard, PredictiveAnalyticsCard",
            "ChallengesCard, RewardsCard, NutritionCard (3 variants)",
            "Services: NutritionService, PersonalizationService, MealPlannerService",
            "AI Services: AiRecommendationService, PredictiveAnalyticsService",
            "ChallengesRewardsService, CacheService, DatabaseService",
        ]),
        ("REST API Layer (JSON)", 200, 250, 800, 70, "#334155", [
            "HTTP Endpoints: POST/GET/PUT/DELETE · JWT Auth · JSON Responses",
        ]),
        ("Python Backend (FastAPI)", 50, 340, 1100, 150, "#1e3a5f", [
            "Routers: auth, nutrition, medications, activities, water, weight",
            "symptoms, ai_analytics, chat, community, notifications",
            "Services: ai_service, chat_ai_service, notification_service",
            "dynamic_targets_service, nutrition_calculator",
            "ML: weight_predictor, improved_predictor (TensorFlow/PyTorch)",
            "Caching: Redis-like cache_config · Workers: scheduler",
        ]),
        ("Database Layer (MySQL)", 200, 510, 800, 70, "#334155", [
            "SQLAlchemy ORM · 20+ Tables · Dynamic Targets · Health Metrics",
        ]),
    ]

    # Draw layer backgrounds and text
    for title, x, y, w, h, bg, items in layers:
        draw_rounded_box(draw, (x, y, x+w, y+h), fill=hex_to_rgb(bg), radius=12)
        # Layer label
        draw_centered_text(draw, title, get_font(14, bold=True), x + w//2, y + 16, "#e2e8f0")
        # Items
        for i, item in enumerate(items):
            draw_centered_text(draw, "• " + item, small_font, x + w//2, y + 40 + i*16, "#cbd5e1")

    # Arrows between layers
    mid_x = W//2
    draw_arrow_down(draw, mid_x, 230, 250, "#38bdf8", 3)
    draw_arrow_down(draw, mid_x + 60, 230, 250, "#38bdf8", 3)
    draw_arrow_down(draw, mid_x, 490, 510, "#38bdf8", 3)

    # Right sidebar: tech tags
    tech_x = 50
    tech_y = 600
    tech_items = [
        ("Frontend", "Dart · Flutter 3.x · Provider · GoRouter", "#0ea5e9"),
        ("State", "ChangeNotifier · FutureBuilder · StreamBuilder", "#8b5cf6"),
        ("Backend", "Python · FastAPI · SQLAlchemy · Pydantic", "#f59e0b"),
        ("ML", "Scikit-learn · PyTorch · Linear Regression · Random Forest", "#10b981"),
        ("Auth", "JWT · bcrypt · OAuth2 · Secure Storage", "#ef4444"),
    ]
    draw_rounded_box(draw, (tech_x, tech_y, tech_x+320, tech_y+25+len(tech_items)*30), fill=hex_to_rgb("#1e293b"), radius=10)
    draw_centered_text(draw, "📌 Tech Stack", get_font(14, bold=True), tech_x+160, tech_y+12, "#f8fafc")
    for i, (name, desc, color) in enumerate(tech_items):
        iy = tech_y + 35 + i*30
        draw_rounded_box(draw, (tech_x+10, iy, tech_x+60, iy+22), fill=hex_to_rgb(color), radius=4)
        draw_centered_text(draw, name, get_font(9, bold=True), tech_x+35, iy+11, "#fff")
        draw.text((tech_x+70, iy+3), desc, fill="#94a3b8", font=small_font)

    img.save(os.path.join(OUTPUT_DIR, "diagram-architecture-overview.png"))
    print("✅ diagram-architecture-overview.png")

# ============================================================
# FLOWCHART 2: Screen Navigation Flow
# ============================================================
def create_navigation_flow():
    W, H = 1200, 900
    img = Image.new("RGB", (W, H), "#0f172a")
    draw = ImageDraw.Draw(img)

    title_font = get_font(22, bold=True)
    box_font = get_font(12)
    small_font = get_font(10)

    draw_centered_text(draw, "🧭 Screen Navigation Flow", title_font, W//2, 25, "#f8fafc")
    draw_centered_text(draw, "HealthMate - Complete User Journey", get_font(12), W//2, 53, "#94a3b8")

    screens = {
        # (x, y, w, h, text, color, desc)
        "splash": (440, 75, 320, 50, "Splash / Login Screen", "#3b82f6", "Auth → JWT"),
        "services": (100, 180, 250, 80, "Services Screen\n(Home)", "#0ea5e9", "Main Hub"),
        "dash": (850, 180, 250, 80, "Water Dashboard", "#0ea5e9", "Water Tracking"),
        "nutrition": (100, 300, 250, 80, "Nutrition Dashboard", "#10b981", "Meal Logging"),
        "ai": (400, 300, 280, 80, "🤖 AI Insights Hub", "#8b5cf6", "AI Features Center"),
        "mealplanner": (750, 300, 250, 80, "Meal Planner", "#f59e0b", "Weekly Planning"),
        "personalize": (750, 420, 250, 80, "Personalization", "#f59e0b", "Goals & Prefs"),
        "addmeal": (100, 420, 250, 80, "Add Meal", "#10b981", "Food Entry"),
        "mealsuggest": (100, 540, 250, 80, "Meal Suggestions", "#10b981", "AI Recommendations"),
        "mealhistory": (100, 660, 250, 80, "Meal History", "#10b981", "Past Meals"),
        "aicard1": (400, 450, 280, 55, "AI Recommendations", "#a78bfa", "Smart Meal Ideas"),
        "aicard2": (400, 530, 280, 55, "Predictive Analytics", "#a78bfa", "Health Forecast"),
        "aicard3": (400, 610, 280, 55, "Active Challenges", "#a78bfa", "Gamification"),
        "aicard4": (400, 690, 280, 55, "Rewards & Badges", "#a78bfa", "Achievements"),
        "activities": (850, 540, 250, 80, "Activities / Walking", "#0ea5e9", "Exercise Logs"),
        "meds": (850, 420, 250, 80, "Medications", "#0ea5e9", "Medication Tracking"),
        "symptoms": (850, 660, 250, 80, "Symptoms Tracker", "#0ea5e9", "Health Logs"),
        "weight": (500, 780, 200, 50, "Weight Tracking", "#3b82f6", "Progress"),
    }

    for key, (x, y, w, h, text, color, desc) in screens.items():
        draw_rounded_box(draw, (x, y, x+w, y+h), fill=hex_to_rgb(color), radius=8)
        lines = text.split('\n')
        for i, line in enumerate(lines):
            draw_centered_text(draw, line, box_font, x + w//2, y + h//2 - 6 + i*16, "#ffffff")
        # desc label
        draw_centered_text(draw, desc, get_font(8), x + w//2, y + h + 10, "#64748b")

    # Navigation arrows
    def nav_arrow(x1, y1, x2, y2, label=""):
        draw_arrow(draw, x1, y1, x2, y2, "#475569", 2)
        if label:
            mx, my = (x1+x2)//2, (y1+y2)//2
            draw_centered_text(draw, label, get_font(8), mx, my-8, "#64748b")

    # Splash → Services
    nav_arrow(600, 125, 225, 180, "Login")

    # Splash → Water
    nav_arrow(600, 125, 975, 180)

    # Services → Nutrition
    draw_arrow(draw, 225, 260, 225, 300, "#475569", 2)

    # Services → AI
    draw_arrow(draw, 350, 220, 400, 340, "#475569", 2)

    # Services → MealPlanner
    draw_arrow(draw, 350, 220, 750, 340, "#475569", 2)

    # Services → Meds
    draw_arrow(draw, 350, 220, 850, 420, "#475569", 2)

    # Services → Personalize
    draw_arrow(draw, 350, 220, 750, 420, "#475569", 2)

    # Nutrition → AddMeal
    draw_arrow(draw, 225, 380, 225, 420, "#475569", 2)

    # Nutrition → MealSuggest
    draw_arrow(draw, 225, 380, 225, 540, "#475569", 2)

    # Nutrition → MealHistory
    draw_arrow(draw, 225, 380, 225, 660, "#475569", 2)

    # AI Hub → AI Cards
    draw_arrow(draw, 540, 380, 540, 450, "#475569", 2)
    draw_arrow(draw, 540, 505, 540, 530, "#475569", 2)
    draw_arrow(draw, 540, 585, 540, 610, "#475569", 2)
    draw_arrow(draw, 540, 665, 540, 690, "#475569", 2)

    # Services → Activities, Symptoms, Weight
    draw_arrow(draw, 350, 220, 975, 540, "#475569", 2)
    draw_arrow(draw, 975, 260, 975, 420, "#475569", 2)

    # Legend
    lx, ly = 40, 780
    draw_rounded_box(draw, (lx, ly, lx+310, ly+100), fill=hex_to_rgb("#1e293b"), radius=8)
    draw_centered_text(draw, "📋 Legend", get_font(12, bold=True), lx+155, ly+12, "#f8fafc")
    legend_items = [
        ("🔵", "Auth / Primary", "#3b82f6"),
        ("🟢", "Nutrition Module", "#10b981"),
        ("🟣", "AI Module", "#8b5cf6"),
        ("🟡", "Planning Module", "#f59e0b"),
        ("🔷", "Health Tracking", "#0ea5e9"),
    ]
    for i, (icon, name, color) in enumerate(legend_items):
        draw_rounded_box(draw, (lx+10, ly+30+i*14, lx+14, ly+34+i*14), fill=hex_to_rgb(color), radius=2)
        draw.text((lx+22, ly+27+i*14), f"{name}", fill="#cbd5e1", font=get_font(9))

    # Stats
    draw_rounded_box(draw, (900, 770, W-30, 870), fill=hex_to_rgb("#1e293b"), radius=8)
    stats_text = "📊 19+ Screens  ·  4 Major Modules  ·  10+ Services  ·  4 AI Features"
    draw_centered_text(draw, stats_text, get_font(12, bold=True), 1050, 820, "#38bdf8")

    img.save(os.path.join(OUTPUT_DIR, "diagram-navigation-flow.png"))
    print("✅ diagram-navigation-flow.png")

# ============================================================
# FLOWCHART 3: AI Feature Architecture
# ============================================================
def create_ai_architecture():
    W, H = 1100, 800
    img = Image.new("RGB", (W, H), "#0f172a")
    draw = ImageDraw.Draw(img)

    title_font = get_font(20, bold=True)
    box_font = get_font(12)
    small_font = get_font(10)

    draw_centered_text(draw, "🤖 AI Features Architecture", title_font, W//2, 25, "#f8fafc")
    draw_centered_text(draw, "Phase C: Models → Services → Widgets → Integration", get_font(12), W//2, 53, "#94a3b8")

    # Layer 1: AI Models (ai_models.dart)
    draw_rounded_box(draw, (50, 70, 1000, 110), fill=hex_to_rgb("#1e3a5f"), radius=10)
    draw_centered_text(draw, "📦 Data Models (ai_models.dart)", get_font(14, bold=True), 550, 84, "#e2e8f0")
    models = "RecommendationContext · MealTimeContext · AiMealRecommendation · NutritionPredictionReport · GamificationStats · Challenge · Reward · UserNutritionData"
    draw_centered_text(draw, models, get_font(10), 550, 108, "#94a3b8")
    draw_centered_text(draw, "All models use fromJson/toJson with factory constructors", get_font(9), 550, 124, "#64748b")
    draw_centered_text(draw, "→", get_font(18), 550, 145, "#475569")
    draw_centered_text(draw, "feeds into", get_font(9), 550, 163, "#475569")

    # Layer 2: AI Services
    sy = 180
    draw_rounded_box(draw, (50, sy, 1000, 200), fill=hex_to_rgb("#1e293b"), radius=10)
    draw_centered_text(draw, "⚙️ AI Services Layer", get_font(14, bold=True), 550, sy+14, "#e2e8f0")

    services = [
        ("AiRecommendationService", 80, sy+35, "getSmartRecommendations(context)\ngetDailyRecommendations()\ngetWeeklyTrends()\n_handleApiResponse()", "#8b5cf6"),
        ("PredictiveAnalyticsService", 390, sy+35, "generatePredictionReport(userData)\ngetNutritionForecast()\ngetHealthRiskAssessment()\ngetPatternInsights()", "#0ea5e9"),
        ("ChallengesRewardsService", 700, sy+35, "getActiveChallenges()\ngetGamificationStats()\ngetAvailableRewards()\nclaimReward()", "#f59e0b"),
    ]
    for name, sx, sy2, methods, color in services:
        draw_rounded_box(draw, (sx, sy2, sx+280, sy2+140), fill=hex_to_rgb("#0f172a"), radius=8)
        draw_rounded_box(draw, (sx, sy2, sx+280, sy2+28), fill=hex_to_rgb(color), radius=6)
        draw_centered_text(draw, name, get_font(10, bold=True), sx+140, sy2+14, "#ffffff")
        for i, m in enumerate(methods.split('\n')):
            draw.text((sx+12, sy2+36+i*20), f"▸ {m}", fill="#94a3b8", font=get_font(9))

    # Arrow down
    draw_centered_text(draw, "↓", get_font(18), 550, 385, "#475569")
    draw_centered_text(draw, "provides data to", get_font(9), 550, 400, "#475569")

    # Layer 3: UI Widgets
    wy = 415
    draw_rounded_box(draw, (50, wy, 1000, wy+170), fill=hex_to_rgb("#1e3a5f"), radius=10)
    draw_centered_text(draw, "🎨 AI UI Widget Layer", get_font(14, bold=True), 550, wy+14, "#e2e8f0")

    widgets = [
        ("AiRecommendationCard", 80, wy+35, "Params: goal, diseases, preferences,\ntargetCalories\n\nShows: Smart meal recommendations\nwith nutrition breakdown", "#8b5cf6"),
        ("PredictiveAnalyticsCard", 320, wy+35, "Params: userData (UserNutritionData?)\n\nShows: Weight prediction chart,\nhealth scores, risk assessment", "#0ea5e9"),
        ("ChallengesCard", 560, wy+35, "Params: (none)\n\nShows: Active challenges list,\nprogress bars, daily streaks", "#f59e0b"),
        ("RewardsCard", 800, wy+35, "Params: (none)\n\nShows: Available rewards,\nbadges, achievement grid", "#10b981"),
    ]
    for name, wx, wy2, desc, color in widgets:
        draw_rounded_box(draw, (wx, wy2, wx+200, wy2+120), fill=hex_to_rgb("#0f172a"), radius=8)
        draw_rounded_box(draw, (wx, wy2, wx+200, wy2+24), fill=hex_to_rgb(color), radius=6)
        draw_centered_text(draw, name, get_font(9, bold=True), wx+100, wy2+12, "#ffffff")
        lines = desc.split('\n')
        for i, line in enumerate(lines):
            draw.text((wx+8, wy2+30+i*14), line, fill="#94a3b8", font=get_font(8))

    # Arrow down
    draw_centered_text(draw, "↓", get_font(18), 550, 590, "#475569")
    draw_centered_text(draw, "integrated into", get_font(9), 550, 605, "#475569")

    # Layer 4: Integration
    iy = 620
    draw_rounded_box(draw, (50, iy, 1000, iy+80), fill=hex_to_rgb("#334155"), radius=10)
    draw_centered_text(draw, "🔄 Integration (Hub Screen + Existing Screens)", get_font(14, bold=True), 550, iy+16, "#e2e8f0")
    draw_centered_text(draw, "AIInsightsScreen (Hub) ← aiInsightsButton in NutritionDashboard · ServicesScreen redirect →", get_font(11), 550, iy+45, "#94a3b8")
    draw_centered_text(draw, "All 4 widgets rendered in a scrollable ListView with shimmer loading states", get_font(10), 550, iy+64, "#64748b")

    # Right sidebar: File list
    fx, fy = 70, 710
    draw_rounded_box(draw, (fx, fy, W-70, 770), fill=hex_to_rgb("#1e293b"), radius=8)
    files = "📁 Phase C Files:  ai_models.dart · ai_recommendation_service.dart · predictive_analytics_service.dart · challenges_rewards_service.dart · ai_recommendation_card.dart · predictive_analytics_card.dart · challenges_card.dart · rewards_card.dart · ai_insights_screen.dart"
    draw_centered_text(draw, files, get_font(9), 550, 740, "#38bdf8")

    img.save(os.path.join(OUTPUT_DIR, "diagram-ai-architecture.png"))
    print("✅ diagram-ai-architecture.png")

# ============================================================
# FLOWCHART 4: Phased Implementation Progress
# ============================================================
def create_phased_progress():
    W, H = 1000, 800
    img = Image.new("RGB", (W, H), "#0f172a")
    draw = ImageDraw.Draw(img)

    title_font = get_font(20, bold=True)
    box_font = get_font(12)
    small_font = get_font(10)
    tick_font = get_font(14)

    draw_centered_text(draw, "📈 Phased Implementation Progress", title_font, W//2, 25, "#f8fafc")
    draw_centered_text(draw, "14/18 Items Completed · Phase D Pending", get_font(12), W//2, 53, "#94a3b8")

    phases = [
        ("Phase 1: Accessibility & Navigation", 80, "#3b82f6", "#1e3a5f", [
            ("✅", "RTL Support & Semantics Widgets", "Added Directionality widget, Semantics to all interactive elements"),
            ("✅", "NutritionCard with 3 Constructors", ".defaultStyle(), .tips(), .flat() for different use cases"),
            ("✅", "DesignConstants Refactoring", "sectionHeader(), spacingTokens, shared design tokens"),
            ("✅", "AppColors Restructuring", "Modular color constants with semantic naming"),
            ("✅", "Accessibility Improvements", "Screen readers, contrast ratios, tap targets ≥48px"),
            ("✅", "Navigation Patterns", "Consistent back navigation, deep linking support"),
        ]),
        ("Phase 2: Meal Planner & Personalization", 200, "#10b981", "#0f2d1a", [
            ("✅", "Meal Planner Screen + Service", "Weekly meal calendar, CRUD operations, meal_plan_model.dart"),
            ("✅", "Personalization Service", "preferences_model.dart, user goals, dietary preferences storage"),
        ]),
        ("Phase C: AI Features (6 items)", 380, "#8b5cf6", "#1e1035", [
            ("✅", "AI Data Models", "ai_models.dart: RecommendationContext, AiMealRecommendation, etc."),
            ("✅", "AI Recommendation Service + Card", "Smart recommendations with time context, nutrition breakdown"),
            ("✅", "Predictive Analytics Service + Card", "Weight prediction, health scores, risk assessment visualization"),
            ("✅", "Challenges & Rewards Service + Cards", "Gamification: daily streaks, badges, achievement system"),
            ("✅", "AI Insights Hub Screen", "Scrollable hub integrating all 4 AI widgets with shimmer loading"),
            ("✅", "Integration (Dashboard + Services)", "AI button in NutritionDashboard, menu redirect in ServicesScreen"),
        ]),
        ("Phase D: Community Features (4 items)", 620, "#f59e0b", "#2d1f05", [
            ("⬜", "Community Forum Screen", "Post questions, share tips with other users"),
            ("⬜", "Community Service + Models", "Backend API, data models for community features"),
            ("⬜", "Leaderboard & Social Features", "Friend challenges, weekly rankings, social sharing"),
            ("⬜", "Integration into Navigation", "Add community tab to nav bar and services menu"),
        ]),
    ]

    for title, y, color, bg, items in phases:
        # Phase header
        draw_rounded_box(draw, (50, y, 950, y+30), fill=hex_to_rgb(color), radius=6)
        draw_centered_text(draw, title, get_font(12, bold=True), 500, y+15, "#ffffff")

        # Items
        for i, (status, name, desc) in enumerate(items):
            iy = y + 35 + i*28
            # Status icon
            draw.text((55, iy+2), status, fill="#22c55e" if "✅" in status else "#94a3b8", font=tick_font)
            # Name
            draw.text((85, iy+2), name, fill="#e2e8f0", font=box_font)
            # Description
            draw.text((85, iy+16), desc, fill="#64748b", font=get_font(9))

            # Separator
            if i < len(items) - 1:
                draw.line([(85, iy+26), (920, iy+26)], fill="#1e293b", width=1)

    # Progress bar at bottom
    bar_y = 745
    draw_rounded_box(draw, (100, bar_y, 900, bar_y+30), fill=hex_to_rgb("#1e293b"), radius=15)
    pct = 14/18
    draw_rounded_box(draw, (100, bar_y, 100 + int(800*pct), bar_y+30), fill=hex_to_rgb("#22c55e"), radius=15)
    draw_centered_text(draw, f"78% Complete (14/18 items)  —  flutter analyze: 0 errors", get_font(11, bold=True), 500, bar_y+15, "#ffffff")

    img.save(os.path.join(OUTPUT_DIR, "diagram-phased-progress.png"))
    print("✅ diagram-phased-progress.png")

# ============================================================
# FLOWCHART 5: Data Flow Diagram
# ============================================================
def create_data_flow():
    W, H = 1100, 750
    img = Image.new("RGB", (W, H), "#0f172a")
    draw = ImageDraw.Draw(img)

    title_font = get_font(20, bold=True)
    box_font = get_font(11)

    draw_centered_text(draw, "📊 Data Flow Diagram", title_font, W//2, 25, "#f8fafc")
    draw_centered_text(draw, "User Input → UI → Service → API → Backend → Database", get_font(12), W//2, 53, "#94a3b8")

    # User Input (top)
    draw_rounded_box(draw, (300, 70, 800, 120), fill=hex_to_rgb("#3b82f6"), radius=10)
    draw_centered_text(draw, "👤 User Input", get_font(14, bold=True), 550, 86, "#ffffff")
    draw_centered_text(draw, "Screen taps · Form submissions · Voice input · Biometric", get_font(10), 550, 106, "#bfdbfe")

    draw_arrow_down(draw, 550, 120, 140)

    # Flutter UI
    draw_rounded_box(draw, (100, 140, 1000, 210), fill=hex_to_rgb("#1e3a5f"), radius=10)
    draw_centered_text(draw, "📱 Flutter UI Layer", get_font(14, bold=True), 550, 155, "#e2e8f0")

    ui_flows = [
        ("Screens", "NutritionDashboard\nAIInsightsScreen\nServicesScreen\nMealPlannerScreen", 140, 175),
        ("Widgets", "AiRecommendationCard\nPredictiveAnalyticsCard\nNutritionCard\nChallengesCard", 450, 175),
        ("State", "ChangeNotifier\nStatefulWidget\nFutureBuilder\nStreamBuilder", 760, 175),
    ]
    for name, content, ux, uy in ui_flows:
        draw_rounded_box(draw, (ux, uy, ux+200, uy+70), fill=hex_to_rgb("#0f172a"), radius=6)
        draw_centered_text(draw, name, get_font(10, bold=True), ux+100, uy+10, "#38bdf8")
        for i, line in enumerate(content.split('\n')):
            draw_centered_text(draw, line, get_font(9), ux+100, uy+28+i*14, "#94a3b8")

    draw_arrow_down(draw, 550, 210, 230)

    # Service Layer
    draw_rounded_box(draw, (100, 230, 1000, 300), fill=hex_to_rgb("#1e293b"), radius=10)
    draw_centered_text(draw, "🔧 Flutter Service Layer", get_font(14, bold=True), 550, 245, "#e2e8f0")

    svc_flows = [
        ("NutritionService", "HTTP GET/POST /api/nutrition\nCacheService (local DB)", 140, 265),
        ("AiRecommendationService", "POST /api/ai/recommendations\nContext: goal, diseases, prefs", 380, 265),
        ("PredictiveAnalyticsService", "POST /api/ai/predict\nUserNutritionData → Report", 620, 265),
        ("ChallengesService", "GET/POST /api/gamification\nChallenges, Rewards, Stats", 860, 265),
    ]
    for name, desc, sx, sy in svc_flows:
        draw_rounded_box(draw, (sx, sy, sx+180, sy+50), fill=hex_to_rgb("#0f172a"), radius=6)
        draw_centered_text(draw, name, get_font(9, bold=True), sx+90, sy+8, "#f59e0b")
        lines = desc.split('\n')
        for i, line in enumerate(lines):
            draw_centered_text(draw, line, get_font(8), sx+90, sy+22+i*14, "#94a3b8")

    draw_arrow_down(draw, 550, 300, 320)

    # API Layer
    draw_rounded_box(draw, (200, 320, 900, 370), fill=hex_to_rgb("#334155"), radius=10)
    draw_centered_text(draw, "🌐 REST API (JSON over HTTP)", get_font(13, bold=True), 550, 336, "#e2e8f0")
    draw_centered_text(draw, "JWT Bearer Auth · Content-Type: application/json · Error codes: 200/400/401/404/500", get_font(9), 550, 356, "#94a3b8")

    draw_arrow_down(draw, 550, 370, 390)

    # Backend
    draw_rounded_box(draw, (100, 390, 1000, 470), fill=hex_to_rgb("#0f2937"), radius=10)
    draw_centered_text(draw, "🐍 Python Backend (FastAPI)", get_font(14, bold=True), 550, 405, "#e2e8f0")

    be_items = [
        ("Routers", "auth, nutrition, medications,\nactivities, ai_analytics, chat", 140, 425),
        ("Services", "ai_service, notification_service,\ndynamic_targets_service", 380, 425),
        ("ML Models", "weight_predictor,\nimproved_predictor", 620, 425),
        ("Workers", "scheduler, notifications,\ncache invalidation", 860, 425),
    ]
    for name, content, bx, by in be_items:
        draw_rounded_box(draw, (bx, by, bx+180, by+55), fill=hex_to_rgb("#0f172a"), radius=6)
        draw_centered_text(draw, name, get_font(9, bold=True), bx+90, by+8, "#10b981")
        for i, line in enumerate(content.split('\n')):
            draw_centered_text(draw, line, get_font(8), bx+90, by+22+i*14, "#94a3b8")

    draw_arrow_down(draw, 550, 470, 500)

    # Database
    draw_rounded_box(draw, (250, 500, 850, 560), fill=hex_to_rgb("#1e3a5f"), radius=10)
    draw_centered_text(draw, "🗄️ MySQL Database (SQLAlchemy ORM)", get_font(13, bold=True), 550, 518, "#e2e8f0")
    draw_centered_text(draw, "20+ Tables · Users, Nutrition, Meals, Medications, Activities, Water, Weight, Symptoms, Challenges, Rewards, Dynamic Targets", get_font(9), 550, 544, "#94a3b8")

    # Flows disclaimer
    draw_rounded_box(draw, (100, 600, 1000, 720), fill=hex_to_rgb("#1e293b"), radius=10)
    draw_centered_text(draw, "💡 Key Data Flows", get_font(14, bold=True), 550, 615, "#e2e8f0")
    flows_text = [
        ("1.", "User logs meal → NutritionDashboard → AddMealScreen → NutritionService → POST /api/nutrition → Backend → MySQL"),
        ("2.", "User views AI recommendations → AIInsightsScreen → AiRecommendationCard → AiRecommendationService → POST /api/ai/recommendations"),
        ("3.", "Predictive Analytics → PredictiveAnalyticsCard → PredictiveAnalyticsService → POST /api/ai/predict → ML model inference"),
        ("4.", "Gamification → ChallengesCard/RewardsCard → ChallengesRewardsService → GET /api/gamification/stats → Backend"),
    ]
    for i, (num, line) in enumerate(flows_text):
        draw.text((120, 640+i*20), f"{num} {line}", fill="#94a3b8", font=get_font(9))

    img.save(os.path.join(OUTPUT_DIR, "diagram-data-flow.png"))
    print("✅ diagram-data-flow.png")

# ============================================================
# FLOWCHART 6: Complete Feature Map
# ============================================================
def create_feature_map():
    W, H = 1100, 800
    img = Image.new("RGB", (W, H), "#0f172a")
    draw = ImageDraw.Draw(img)

    title_font = get_font(20, bold=True)
    box_font = get_font(11)
    small_font = get_font(9)

    draw_centered_text(draw, "🗺️ Complete Feature Map", title_font, W//2, 25, "#f8fafc")
    draw_centered_text(draw, "HealthMate - All Modules & Features", get_font(12), W//2, 53, "#94a3b8")

    modules = [
        ("🍎 Nutrition", 50, 80, "#10b981", [
            "Nutrition Dashboard",
            "Add Meal (Food Search)",
            "Meal Suggestions (AI)",
            "Meal Planner (Weekly)",
            "AI Recommendations",
            "Meal History",
            "Daily Summary",
            "Nutrient Charts",
        ]),
        ("💧 Water", 50, 280, "#0ea5e9", [
            "Water Dashboard",
            "Quick Add / Custom Amount",
            "Daily Progress Chart",
            "Water Stats & History",
            "Smart Reminders",
            "Personalized Tips",
        ]),
        ("🏃 Activities", 350, 80, "#f59e0b", [
            "Activity Dashboard",
            "Walking Tracker",
            "Exercise Logs",
            "Activity Plans",
            "Progress Charts",
            "Goal Setting",
        ]),
        ("💊 Medications", 350, 280, "#ef4444", [
            "Medication Dashboard",
            "Add/Edit Medications",
            "Schedule Management",
            "Refill Reminders",
            "Medication History",
        ]),
        ("🤖 AI Features", 650, 80, "#8b5cf6", [
            "AI Insights Hub (Main)",
            "Smart Recommendations",
            "Predictive Analytics",
            "Health Risk Assessment",
            "Weight Prediction",
            "Pattern Insights",
            "Gamification (Challenges)",
            "Rewards & Badges",
        ]),
        ("❤️ Health Tracking", 650, 280, "#ec4899", [
            "Symptoms Tracker",
            "Weight Tracking",
            "Health Metrics",
            "Dynamic Targets",
            "Behavioral Nudges",
            "Health Reports",
        ]),
        ("🔐 Auth & Profile", 50, 480, "#3b82f6", [
            "Login / Register",
            "Profile Management",
            "Personalization Goals",
            "Dietary Preferences",
            "Disease Management",
        ]),
        ("📊 Analytics", 350, 480, "#14b8a6", [
            "Data Analysis",
            "Nutrition Analysis",
            "Water Analysis",
            "Activity Analysis",
            "Export Data",
        ]),
        ("🌐 Community", 650, 480, "#f97316", [
            "Community Forum",
            "Social Sharing",
            "Leaderboard",
            "Friend Challenges",
        ]),
    ]

    for name, mx, my, color, items in modules:
        # Module card
        draw_rounded_box(draw, (mx, my, mx+280, my+180), fill=hex_to_rgb("#1e293b"), radius=10)
        # Header
        draw_rounded_box(draw, (mx, my, mx+280, my+30), fill=hex_to_rgb(color), radius=8)
        draw_centered_text(draw, name, get_font(12, bold=True), mx+140, my+15, "#ffffff")
        # Items
        for i, item in enumerate(items):
            draw.text((mx+12, my+38+i*16), f"• {item}", fill="#cbd5e1", font=small_font)

    # Stats bar
    draw_rounded_box(draw, (50, 690, 1050, 760), fill=hex_to_rgb("#1e3a5f"), radius=12)
    stats = [
        ("9 Modules", "Comprehensive coverage"),
        ("40+ Features", "Across all modules"),
        ("14/18 Done", "78% implementation"),
        ("0 Errors", "flutter analyze clean"),
        ("3 Phases", "1, 2, & C completed"),
    ]
    for i, (stat, desc) in enumerate(stats):
        sx = 100 + i*200
        draw_centered_text(draw, stat, get_font(14, bold=True), sx+80, 708, "#38bdf8")
        draw_centered_text(draw, desc, get_font(9), sx+80, 730, "#94a3b8")

    draw_centered_text(draw, "📌 Phase D (Community) in progress · 4 items remaining", get_font(10), 550, 775, "#64748b")

    img.save(os.path.join(OUTPUT_DIR, "diagram-feature-map.png"))
    print("✅ diagram-feature-map.png")

# ============================================================
# RUN ALL
# ============================================================
if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    create_architecture_overview()
    create_navigation_flow()
    create_ai_architecture()
    create_phased_progress()
    create_data_flow()
    create_feature_map()
    print("\n🎉 All 6 flowcharts created successfully!")