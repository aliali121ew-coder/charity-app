# Charity Organization Management System
# نظام إدارة منظمة الخير

A full-stack charity management application built with Flutter (frontend) and Dart Shelf (backend).

---

## Project Structure

```
charity_app/
├── lib/                        # Flutter Frontend
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── theme/              # AppColors, AppTheme (light/dark)
│   │   ├── localization/       # Arabic + English translations
│   │   ├── permissions/        # Role-based access (Admin/Employee)
│   │   └── router/             # go_router with auth guards
│   ├── shared/
│   │   ├── models/             # SubscriberModel, FamilyModel, AidModel, LogModel, UserModel
│   │   ├── providers/          # AuthNotifier, LocaleNotifier, ThemeModeNotifier
│   │   └── widgets/            # KpiStatCard, StatusChip, ChartCard, ActivityLogItem, ...
│   └── features/
│       ├── auth/               # Login page
│       ├── dashboard/          # KPI cards + charts + recent activity
│       ├── subscribers/        # Grid cards, search, filter
│       ├── families/           # Family cards with income/aid stats
│       ├── aid/                # Aid records with approve/distribute actions
│       ├── logs/               # Activity timeline
│       ├── reports/            # Bar/Pie charts with tabs
│       └── settings/           # Profile, theme, language, users
│
└── backend/                    # Dart Shelf HTTP API
    ├── bin/
    │   └── server.dart         # Entry point — mounts all routers
    └── lib/
        ├── models/             # Subscriber, Family, Aid, User (toJson/fromJson)
        ├── repositories/       # Abstract interfaces + Mock implementations
        ├── services/           # AuthService (login, token generation)
        └── routes/             # auth, subscribers, families, aid, logs, reports
```

---

## Frontend (Flutter)

### Features
- **Authentication** — Login with role-based access (Admin / Employee)
- **Dashboard** — KPI cards, line chart (aid trend), donut chart (aid by category), recent lists
- **Subscribers** — Card grid with search, status filter, CRUD actions
- **Families** — Family cards with member count, income level, aid history
- **Aid Management** — Financial, food, medical, seasonal, education aid with approve/distribute workflow
- **Operations Log** — Full activity timeline with action type badges
- **Reports** — Monthly bar charts, type distribution pie charts, geographic breakdown
- **Settings** — Language switch (AR/EN), theme toggle (dark/light), user management

### Tech Stack
| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Navigation + auth redirects |
| `fl_chart` | Line, bar, pie charts |
| `google_fonts` (Cairo) | Bilingual Arabic/English typography |
| `shared_preferences` | Persist locale and theme |

### Run Frontend
```bash
flutter pub get
flutter run -d windows
```

### Demo Credentials
| Role | Email | Password |
|------|-------|----------|
| Admin | admin@charity.org | admin123 |
| Employee | employee@charity.org | emp123 |

---

## Backend (Dart Shelf)

### API Endpoints
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/login` | Login, returns token |
| GET | `/api/subscribers` | List subscribers |
| POST | `/api/subscribers` | Create subscriber |
| PUT | `/api/subscribers/:id` | Update subscriber |
| DELETE | `/api/subscribers/:id` | Delete subscriber |
| GET | `/api/families` | List families |
| GET | `/api/aid` | List aid records |
| POST | `/api/aid/:id/approve` | Approve aid |
| POST | `/api/aid/:id/distribute` | Mark as distributed |
| GET | `/api/logs` | Activity logs |
| GET | `/api/reports/summary` | Dashboard KPIs |
| GET | `/api/reports/monthly` | Monthly totals |
| GET | `/api/reports/yearly` | Yearly totals |
| GET | `/api/reports/aid-by-type` | Aid by category |
| GET | `/health` | Health check |

### Run Backend
```bash
cd backend
dart pub get
dart run bin/server.dart
# Server starts on http://localhost:8080
```

### Architecture
- All routes use auth middleware (Bearer token required except `/api/auth/` and `/health`)
- Mock repositories implement abstract interfaces — swap with real database implementations
- CORS headers enabled for frontend development

---

## Localization
The app supports full **Arabic (RTL)** and **English (LTR)** switching at runtime. Toggle via Settings page or the language button in the sidebar. The locale is persisted across app restarts.

## Permissions
| Permission | Admin | Employee |
|-----------|-------|----------|
| View all pages | ✅ | ✅ |
| Add/Edit/Delete subscribers | ✅ | ✅ |
| Add/Edit/Delete families | ✅ | ✅ |
| Approve/Distribute aid | ✅ | ✅ |
| Manage users | ✅ | ❌ |
| Edit organization settings | ✅ | ❌ |
