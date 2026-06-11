# Drive Analysis Platform (DAP) — PPT Content

---

## SLIDE 1 — Title Slide

**Drive Analysis Platform**
*AI-Powered EV Fleet Telemetry & Range Prediction System*

- Frontend: Flutter (Web App)
- Backend: Supabase (PostgreSQL + RPC)
- ML Engine: Physics-based regression simulation
- Dataset: Real-world EV telemetry — 5,000 trip records, 10 drivers, 3 brands

---

## SLIDE 2 — Problem Statement

Electric vehicle fleets generate enormous amounts of telemetry data — battery health, trip energy, overspeed events, income, charging states — but most fleet managers and drivers have no centralized tool to make sense of it.

**Key gaps:**
- No real-time fleet status visibility (running vs. charging vs. idle)
- No per-driver safety and income analytics
- No intelligent range prediction based on live trip parameters
- No actionable insights from historical telemetry data

**DAP solves all of this** in a single web application with two role-based views: Admin and Driver.

---

## SLIDE 3 — Tech Stack

| Layer | Technology |
|---|---|
| Frontend Framework | Flutter (Web) |
| Language | Dart 3.x |
| Backend / Database | Supabase (PostgreSQL) |
| Auth | Supabase custom RPC (username + password) |
| State Management | Provider |
| Charts & Visualizations | fl_chart |
| Fonts | Google Fonts (Outfit + Inter) |
| PDF / Export | pdf, dart:convert |
| Date Formatting | intl |
| Telemetry Data | CSV (5,000 rows, parsed via rootBundle) |

**Why Flutter Web?**
Single codebase, pixel-perfect dark glassmorphic UI, responsive across desktop and mobile without compromise.

**Why Supabase?**
Open-source Firebase alternative with PostgreSQL, instant REST/RPC APIs, and a generous free tier. The app also ships with a full in-memory mock/demo mode — no Supabase setup required to run.

---

## SLIDE 4 — System Architecture

```
┌─────────────────────────────────────────┐
│           Flutter Web App               │
│                                         │
│  ┌──────────────┐  ┌──────────────────┐ │
│  │  Admin UI    │  │    Driver UI     │ │
│  │  (5 tabs)    │  │  (6 screens)     │ │
│  └──────┬───────┘  └────────┬─────────┘ │
│         │                   │           │
│  ┌──────▼───────────────────▼─────────┐ │
│  │         Provider State Layer        │ │
│  │  AdminController / DriverController │ │
│  │  PredictionController / AuthCtrl    │ │
│  └──────────────────┬─────────────────┘ │
│                     │                   │
│  ┌──────────────────▼─────────────────┐ │
│  │       Services Layer               │ │
│  │  SupabaseService / PredictionSvc   │ │
│  │  AnalyticsService / TelemetryCSV   │ │
│  └──────────────────┬─────────────────┘ │
└─────────────────────┼───────────────────┘
                      │
          ┌───────────▼────────────┐
          │   Supabase Backend     │
          │  PostgreSQL + RPC      │
          │  (Live or Demo Mode)   │
          └────────────────────────┘
```

---

## SLIDE 5 — Role-Based Access

Two distinct portals with role-based routing and route guards:

**Admin Portal**
- Login: username `admin` / password `adminpassword123`
- Full fleet visibility across all drivers and vehicles
- 5 dashboard tabs, global filters, CSV/PDF export

**Driver Portal**
- Login: username `elon_musk` / password `driverpassword123`
- Personal vehicle telemetry, range prediction, trip history
- Individual analytics screen with personalized charts

---

## SLIDE 6 — Admin Dashboard Overview

The Admin dashboard has a persistent left sidebar (desktop) with 5 navigation tabs:

1. **KPI Dashboard** — Fleet overview with 8 KPI cards
2. **20 Visualizations** — 5 categories of advanced charts
3. **Driver Management Table** — Sortable, paginated, exportable
4. **Automated Strategic Insights** — AI-generated alerts
5. **Telemetry KPI Dashboard** — Real CSV-powered analytics

A slide-out **Global Filters panel** on the right allows filtering by:
- Driver ID (text search)
- Car name (text search)
- Running mode (City / Highway)
- Vehicle condition (Working / Garage)
- Time presets (Day / Week / Month / Year)

---

## SLIDE 7 — Admin: KPI Dashboard (Tab 1)

**8 Fleet-Level KPI Cards:**
- Total Registered Drivers
- Total Fleet Vehicles
- Active Operational Vehicles
- Garage Mode Status
- Average Estimated Range (km)
- Average Fleet Efficiency (%)
- Fleet Monthly Income Average
- Total Range Predictions Logged

Each card has a colour-coded icon and a system telemetry summary panel below showing live database status.

---

## SLIDE 8 — Admin: 20 Visualizations (Tab 2)

Organized into 5 filterable category tabs:

**Fleet Overview**
- Battery Capacity Distribution (bar — <50kWh / 50–80kWh / >80kWh)
- Vehicle Weight Analysis (bar — light / mid / heavy)
- City vs Highway Usage (pie)
- Vehicle Condition Distribution (pie — Active / Garage)

**Performance Metrics**
- Driver Growth Trend (line)
- Monthly Prediction Trend (bar)
- Average Speed Analysis (bar)
- Monthly Income Distribution (bar)

**Battery & Energy**
- Car-wise Performance Indices (bar)
- Driver-wise Performance Indices (bar)
- Vehicle Health Score Distribution (bar)
- Battery Health State Trend (line)

**Financial Analysis**
- Cost Analysis Dashboard (line trend)
- Range Prediction Trends (line)
- Service Requirement Forecast (bar)
- Monthly Vehicle Usage Hours (bar)

**Health & Risk**
- Risk Analysis Dashboard (bar)
- Energy Consumption Analysis (bar)
- Driver Efficiency Rankings (list)
- Vehicle Performance Leaderboard (list)

---

## SLIDE 9 — Admin: Driver Management Table (Tab 3)

A fully interactive data table with:
- **11 columns**: Driver ID, Name, Email, Car Model, Battery (kWh), Weight (kg), Speed (km/h), Income ($), Condition, Running Mode, Created Date
- **Click-to-sort** on every column (ascending / descending)
- **Search bar** filtering rows in real-time
- **Pagination**: 5 / 10 / 20 rows per page selector
- **Export buttons**:
  - Export CSV (downloads driver data as .csv)
  - Export Excel (CSV format, Excel-compatible)
  - Export PDF (structured text report with all driver + prediction stats)

---

## SLIDE 10 — Admin: Automated Strategic Insights (Tab 4)

AI-generated fleet intelligence with 6 panels:

**Fleet Anomalies & Energy Outlook**
- Fleet average energy draw (Wh/km) vs benchmark
- Total net CO₂ savings across fleet

**Top Performing Drivers** — Ranked by driver efficiency score

**Lowest Efficiency Vehicles** — Ranked by highest Wh/km draw

**Vehicles Requiring Maintenance** — Flagged when maintenance alert score > 50%

**Battery Cell Health SOH Alerts** — Flagged when battery health < 85%

**Critical Risk Warnings** — Real-time alert cards for vehicles with HIGH risk level, showing driver name, car, speed, and health score

---

## SLIDE 11 — Admin: Telemetry KPI Dashboard (Tab 5)

Powered by 5,000 real telemetry records (CSV). Contains 8 sections:

**1. Filter Panel**
- Multi-driver chip selector (tap to toggle, multiple simultaneous)
- Date presets: All Time / Last 1 Month / Last 2 Months / Last 3 Months
- Brand filter, Weather filter, City/Highway mode filter
- Compare Mode toggle

**2. 10 KPI Cards**
Total Trips · Total Income · Distance Covered · Energy Consumed · Avg Battery Health · Avg Speed · Safety Events · Avg Idle Time · Avg SOC End · Active Drivers

**3. Fleet Status Panel**
- Donut chart: Running / Charging / Garage state distribution
- 3 summary badges with counts
- Vehicle listing per state (vehicle ID, driver, car name, SOC%, brand)
- State logic: Running = active=1 | Charging = active=0 + SOC rising | Garage = active=0 + SOC flat

**4. Expense Analysis Panel**
- 1 Month / 2 Month / 3 Month toggle
- Brand filter chips (Volkswagen / Tata / Hyundai)
- Summary: Total Cost · Total Trips · Avg Cost per Trip · Energy Consumed
- Weekly cost trend line chart with gradient fill and tooltips
- Brand cost breakdown bar chart with gradient bars
- Brand legend pills with % share of fleet total

**5. Overspeed Violations Insight**
- Risk-tier colour-coded bar chart (CRITICAL ≥2000 / HIGH ≥500 / MEDIUM ≥100 / SAFE <100)
- Tooltip: violation count, max speed, avg speed, risk tier
- Per-driver detail rows with relative progress bars
- Fleet summary badges: Total · Critical · High count

**6. Income Ranking Panel**
- 🥇🥈🥉 Podium cards for top 3 earners
- Full descending bar chart (gradient bars, gold/silver/bronze + driver colours)
- Fleet average annotation line
- Full ranked list: rank badge, driver info, trips, distance, ₹/km rate, income, % of fleet share

**7. Driver Performance Leaderboard**
- All drivers ranked by income
- Click any row to expand: income, distance, efficiency, battery health, overspeed events, hard braking events, total trips

**8. Fleet Alerts Panel**
Auto-generated alerts per driver for:
- Battery degradation (< 85% health)
- High brake wear (> 15%)
- Suspension issues (< 85% health)
- Overdue service (> 180 days)
- Frequent overspeed (> 20 events)

**9. Interactive Charts Grid (8 charts)**
- Revenue by Driver (gradient bar with touch tooltip)
- Energy Efficiency Wh/km — colour-coded green/orange/red
- Battery Health Trend — multi-line, one line per driver with legend
- Trips by Weather — donut, expands on touch
- City vs Highway — donut with percentages
- Weekly Income Trend — multi-line with weekly buckets
- Safety Events — grouped bar (overspeed + hard brake + rapid accel)
- SOC Drop per trip — gradient bar

**10. Compare Mode (activated when 2+ drivers selected)**
- Side-by-side driver cards: all 9 metrics per driver
- Normalised 0–100 grouped bar chart comparing 5 dimensions: Income · Distance · Efficiency · Battery Health · Avg Speed

---

## SLIDE 12 — Driver Dashboard

Each driver sees a personalised telemetry interface with:

**4 KPI Cards** (top strip):
- Battery Capacity (kWh)
- Operating Speed (km/h)
- Vehicle Condition (Working / Garage)
- Drive Type Cycle (City / Highway)

**5 Quick Action Cards:**

| Card | Function |
|---|---|
| Update Vehicle Data | 3-step onboarding form to edit all parameters |
| Predict Range | Opens input form → ML prediction → 20-metric result |
| View History | Filterable prediction log history |
| Download Report | Exports telemetry + prediction summary as .txt |
| My Analytics | Full personal analytics screen |

---

## SLIDE 13 — Driver: Predict Range Flow

**Step 1 — Input Screen** (new dedicated page)
5 input fields with validation:
- Odometer reading (km)
- Current battery percentage (1–100%)
- Car name / model (pre-filled)
- Drive mode toggle — City or Highway (animated chip)
- Travel speed (km/h, pre-filled)

**Step 2 — ML Loading Overlay**
9-phrase animated loading sequence:
- "Establishing telemetry link..."
- "Loading neural weight matrices..."
- "Evaluating aerodynamic drag coefficients..."
- "Running physics regression on odometer data..."
- "Generating AI range prediction result..."

With glowing spinner, inner pulse dot, and "ML ENGINE ACTIVE" badge.

**Step 3 — Prediction Result Screen (20 metrics)**

*Range & Charging:*
1. Estimated Remaining Range (KM) — large hero number display
2. Predicted Battery Drain Rate (% per 10km)
3. Current Battery Percentage — circular gauge
4. Expected Charging Time (11kW AC charger, hours)
5. Predicted Range if Highway (km)
6. Predicted Range if City (km)

*Energy & Efficiency:*
7. Fleet Efficiency Score (%) — linear progress bar
8. Predicted Energy Consumption (Wh/km)
9. Cost per Kilometer ($)
10. Monthly Cost Estimation ($)
11. Driver Efficiency Score (%)
12. Carbon Savings Estimate (kg CO₂)

*Performance & Maintenance:*
13. Vehicle Performance Score (%)
14. Battery Cell Health Score (SOH %) — circular gauge
15. Overall Vehicle Health (%)
16. Maintenance Alert Score (%)
17. Service Recommendation Forecast
18. Vehicle Utilization Score (%)

*Risk & Control:*
19. Operating Risk Level (Low / Medium / High) — colour-coded
20. Recommended Safe Speed (km/h)
21. Recommended Driving Mode

*AI Insights panel:* Personalised natural language diagnostics based on driver name, car, speed, weight, and battery health.

Download PDF Report button exports all 21 metrics to a structured text file.

---

## SLIDE 14 — Driver: Vehicle Onboarding

3-step progressive form for new drivers:

**Step 1 — Driver Profile**
- Driver ID (real-time uniqueness check with debounce)
- Full Name, Email
- Car Name / Model
- Monthly Income, Location

**Step 2 — Vehicle Specifications**
- Battery Capacity (10–100 kWh slider)
- Vehicle Weight (kg)
- Motor Power (kW), Torque (Nm)
- Motor Efficiency (50–100% slider)

**Step 3 — Operating State**
- Drive type: City Cruise / Highway Cruise (card selector)
- Vehicle condition: Working Normal / Garage Mode (card selector)
- Current operational speed
- Date / Time / Month (auto-filled)

Step indicator shows progress with checkmarks. Editing mode reuses the same form, navigating back on save.

---

## SLIDE 15 — Driver: Prediction History

A dedicated screen for browsing all past AI prediction logs:

**Filters:**
- All / Today / This Week / This Month / Custom Date Range (date picker)
- Real-time text search by car name or driver ID

**Each History Card shows:**
- Car model name
- Risk level badge (colour-coded Low / Medium / High)
- Date and time
- Battery % at prediction time
- Efficiency score
- Estimated range (large KM number, right-aligned)

---

## SLIDE 16 — Driver: Personal Analytics Screen

A personal analytics screen loaded from real CSV telemetry data:

**7 KPI Cards:**
Total Trips · Total Income · Total Distance · Energy Consumed · Avg Battery Health · Avg Speed · Safety Events

**6 Interactive Charts:**
- 🔋 Battery health over time (line, daily avg, tooltip on hover)
- 💰 Income per trip (gradient bar, tap to highlight)
- 🏎️ Speed distribution (6 buckets, colour-coded green→red)
- 📉 SOC drop per trip (line with area fill)
- ⚡ Energy consumed per trip (amber line with gradient)
- 🛣️ City vs Highway split (donut, expand on tap)

**Safety & Maintenance Summary:**
- Overspeed Events count
- Hard Braking count
- Rapid Acceleration count
- Avg Brake Wear %
- Avg Suspension Health %
- Days Since Last Service
- Overall Safety Score (0–100, colour-coded progress bar)

**Weather Breakdown:**
Animated progress bars showing % of trips in each weather condition (Clear / Rain / Fog / Cloudy etc.)

---

## SLIDE 17 — Key Insights from the Data

Based on the 5,000-row telemetry dataset (D001–D010, Jan–Feb 2024):

**Income Insights:**
- D002 (VW ID.4 Pro) is the top earner: ₹530,888 total
- D001 (VW ID.4) ranks 2nd: ₹492,668
- All three Volkswagen vehicles rank in the top 5 by income
- Income per km ranges from ~₹3.0 (efficient) to ~₹3.3

**Overspeed Safety Insights:**
- D008 (Kona Long Range), D009 (Creta EV), D010 (Creta EV Pro) each have 3,100+ overspeed violations — classified CRITICAL
- D004 (Nexon EV), D005 (Curvv EV), D006 (Punch EV) have 550–590 — classified HIGH
- D001–D003 (Volkswagen models) are under 60 violations — classified SAFE
- Clear brand pattern: Hyundai/Tata vehicles show higher overspeed rates vs Volkswagen

**Fleet Status:**
- Vehicle state tracked in real-time: Running, Charging, Garage
- Energy cost calculated at ₹8/kWh standard EV tariff
- Brand expense breakdown shows comparative operating cost across Volkswagen, Tata, Hyundai

---

## SLIDE 18 — ML Prediction Engine

The prediction model uses a physics-based regression approach built in Dart:

**Inputs (from driver):**
- Battery %, Odometer, Car name, Speed, City/Highway mode

**Core formulas:**

| Metric | Formula Logic |
|---|---|
| Energy Consumption | base (weight × 0.08) × speed factor × mode factor × efficiency factor |
| Estimated Range | (remaining energy Wh) / (Wh/km consumption) |
| Battery Drain Rate | energy per 10km / total capacity × 100 |
| Battery Health | 100 - weight stress - power stress |
| Charging Time | charge needed kWh / 11kW |
| Efficiency Score | 100 - ((Wh/km - 110) / 2.5) |
| Risk Level | speed × 0.45 + maintenance × 0.55 > 75 = High |
| Carbon Savings | estimated range × 0.105 kg CO₂/km saved vs petrol |

**Outputs: 21 prediction metrics** saved to Supabase and displayed in the result screen.

---

## SLIDE 19 — UI/UX Design System

**Design language: Dark Glassmorphism**

| Element | Detail |
|---|---|
| Background | #08080E — deep pitch black |
| Card surface | #131320 — dark translucent base |
| Primary accent | #00A3FF — electric blue |
| Secondary accent | #0052FF — royal blue |
| Text primary | #FFFFFF |
| Text secondary | #8F9BB3 — slate grey |
| Glass border | #1E293B |
| Typography | Google Fonts: Outfit (headings) + Inter (body) |

**Key UI components:**
- `GlassCard` — backdrop filter blur + gradient fill + border
- `CircularGauge` — custom painted arc gauge with gradient
- `GlassButton` — hover-aware animated gradient button
- `GlassTextField` — styled form inputs with validation
- All charts: `fl_chart` with touch tooltips, gradient fills, animated bars

**Responsive layout:** Desktop sidebar + grid / Mobile drawer + stacked columns — one codebase handles both.

---

## SLIDE 20 — Summary

**Drive Analysis Platform delivers:**

✅ Role-based admin and driver web portals
✅ Real-time fleet KPI monitoring (10 metrics, live filters)
✅ 20 advanced chart visualizations across 5 categories
✅ Telemetry KPI dashboard powered by 5,000 real trip records
✅ Fleet state analysis: Running / Charging / Garage
✅ 3-month expense tracking by brand with trend charts
✅ Overspeed violation ranking with risk tier classification
✅ Income ranking leaderboard with podium visualization
✅ Multi-driver comparison mode (normalized 5-metric radar)
✅ AI range prediction with 21 output metrics
✅ 9-phrase ML loading simulation with animated overlay
✅ Driver personal analytics: 6 charts + safety score + weather breakdown
✅ 3-step vehicle onboarding with real-time Driver ID validation
✅ Prediction history with date filters and search
✅ CSV and PDF report export
✅ Supabase backend with full demo/mock fallback mode
✅ Glassmorphic dark UI, fully responsive, Flutter Web

---

*Built with Flutter · Supabase · fl_chart · Provider · Google Fonts*
