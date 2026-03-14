# Automated Researcher — Flutter UI

A production-grade Flutter mobile UI scaffold for an AI-powered research assistant.

---

## Design System

| Token | Value |
|---|---|
| Background | `#000000` |
| Surface | `#111111` |
| Surface Elevated | `#1A1A1A` |
| Border | `#222222` |
| Border Bright | `#333333` |
| Primary Text | `#FFFFFF` |
| Secondary Text | `#AAAAAA` |
| Muted Text | `#666666` |
| Error | `#FF4444` |
| Success | `#22C55E` |
| Warning | `#F59E0B` |

**Font:** General Sans (geometric humanist sans-serif). Swap to `DM Sans`, `Sora`, or `Plus Jakarta Sans` if unavailable.

---

## Screens

| Screen | Route | Purpose |
|---|---|---|
| Login / Sign Up | `/login` | Email + Google auth |
| Dashboard | `/dashboard` | Create research jobs |
| Progress | `/jobs/:id/progress` | Live pipeline tracker |
| Report Summary | `/jobs/:id/report` | Preview + actions |
| Report Viewer | `/jobs/:id/report/viewer` | Full scrollable report + citations |
| RAG Chat | `/jobs/:id/chat` | Follow-up Q&A |
| History | `/history` | Past research jobs |
| Sources | `/sources` | Collected web sources |
| Profile | `/profile` | Settings + sign out |

---

## Architecture

```
lib/
├── app.dart                     # MaterialApp.router, dark theme
├── main.dart                    # Entry point, orientations, Firebase init
├── core/
│   ├── theme/
│   │   └── app_theme.dart       # AppColors + AppTheme.darkTheme
│   ├── models/
│   │   ├── research_job.dart
│   │   ├── report.dart          # JobReport, ChatResponse
│   │   ├── citation.dart
│   │   └── source_document.dart
│   ├── services/
│   │   ├── api_client.dart      # Dio wrapper + auth interceptor stub
│   │   └── job_service.dart     # All API calls
│   ├── providers/
│   │   ├── app_providers.dart   # ApiClient, JobService
│   │   ├── job_providers.dart   # Creation, polling, list
│   │   ├── chat_providers.dart  # ChatController w/ citations
│   │   └── report_providers.dart
│   ├── routing/
│   │   └── app_router.dart      # GoRouter + custom transitions
│   └── widgets/
│       ├── primary_button.dart  # filled / outlined / ghost variants
│       ├── research_card.dart   # History card with status + progress
│       ├── citation_tile.dart   # Tappable citation with URL launch
│       ├── progress_bar.dart    # Animated with trailing pulse
│       └── skeleton_loader.dart # SkeletonBox, SkeletonResearchCard, SkeletonReport
└── features/
    ├── auth/presentation/login_screen.dart
    ├── dashboard/presentation/dashboard_screen.dart
    ├── progress/presentation/progress_screen.dart
    ├── report/presentation/
    │   ├── report_screen.dart
    │   └── report_viewer_screen.dart
    ├── chat/presentation/chat_screen.dart
    ├── history/presentation/history_screen.dart
    ├── sources/presentation/sources_screen.dart
    ├── profile/presentation/profile_screen.dart
    └── navigation/presentation/main_shell.dart
```

---

## Setup

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Add fonts

Download [General Sans](https://www.fontshare.com/fonts/general-sans) and place the `.otf` files in:
```
assets/fonts/
  GeneralSans-Regular.otf
  GeneralSans-Medium.otf
  GeneralSans-Semibold.otf
  GeneralSans-Bold.otf
```

Alternatively, swap `fontFamily: 'GeneralSans'` for any Google Font in `app_theme.dart` and update `pubspec.yaml` accordingly.

### 3. Set your API base URL

Open `lib/core/services/api_client.dart` and update the `baseUrl`:
```dart
ApiClient({String? baseUrl})
    : _dio = Dio(BaseOptions(
        baseUrl: baseUrl ?? 'https://your-api.example.com',
        ...
      ));
```

### 4. Firebase (optional for now)

If Firebase auth is not yet configured, the app starts without it (the `main.dart` wraps `Firebase.initializeApp()` in a try/catch). When ready:
```bash
flutterfire configure
```

### 5. Run
```bash
flutter run
```

---

## API Endpoints Mapped

| Method | Endpoint | Used in |
|---|---|---|
| `POST` | `/research` | `DashboardScreen` → `JobService.createJob` |
| `GET` | `/research/{id}/status` | `ProgressScreen` → `JobPollingController` |
| `GET` | `/research/{id}/report` | `ReportViewerScreen` → `reportProvider` |
| `POST` | `/research/{id}/ask` | `ChatScreen` → `ChatController` |
| `GET` | `/research/history` | `HistoryScreen` → `jobListProvider` |

---

## Key UI Features

- **Smooth transitions** — fade, slide, and slide-up per route type
- **Animated progress pipeline** — stage list with live icons and pulsing progress bar
- **Skeleton loaders** — history list and report viewer both show shimmer while loading
- **Typing indicator** — three-dot bounce animation while AI responds
- **Pull-to-refresh** — history and sources screens
- **Error + empty states** — every screen handles all three states (loading / error / empty)
- **Citation tiles** — tappable, opens URL in external browser
- **Depth selector cards** — animated press scale + invert selection
- **Bottom nav** — custom animated nav with scale press feedback
