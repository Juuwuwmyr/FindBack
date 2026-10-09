# FindBack — Verified Lost-and-Found System

A Flutter/Supabase mobile app for reporting lost and found items, submitting verified ownership claims, and moderating content. Built with a feature-first clean architecture — every read goes through a Repository, every sensitive write goes through a Supabase Edge Function.

---

## Features

- **User registration & email verification** — GoTrue-backed auth with verified email required before posting
- **Lost/Found report creation with images** — attach up to 5 photos stored in Supabase Storage
- **Full-text search with filters** — PostgreSQL `tsvector` search filtered by category, type, and date range
- **Automatic item matching** — similarity scoring (category 40%, text 40%, date 10%, location 10%; threshold 0.45) runs on every new report via Edge Function
- **Ownership claims with private evidence** — claimants upload evidence images to a private bucket; only the claimant and reporter can see them
- **In-app notifications (real-time)** — Supabase Realtime pushes notification rows to connected clients
- **Admin moderation queue** — flagged reports/claims surface in a dedicated screen; moderators can warn, ban, or delete content with a full audit log

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.x / Dart 3.x |
| State management | Riverpod 2.x (code-gen) |
| Navigation | GoRouter 13.x |
| Backend | Supabase (PostgreSQL + RLS + Storage + Edge Functions) |
| Code generation | build_runner, freezed, json_serializable, riverpod_generator |
| Environment secrets | Envied (compile-time obfuscation) |

---

## Prerequisites

- Flutter SDK ≥ 3.3.0 (`flutter --version` to verify)
- Dart SDK ≥ 3.3.0 (bundled with Flutter)
- A Supabase project — free tier works: https://supabase.com
- Android Studio + Android SDK ≥ 34 (for APK builds)
- Supabase CLI (for deploying Edge Functions): https://supabase.com/docs/guides/cli

---

## Quick Start

```bash
# 1. Install dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 2. Set up environment
cp .env.example .env
# Edit .env and fill in your SUPABASE_URL and SUPABASE_ANON_KEY
# Then regenerate the Envied class:
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run migrations
# In Supabase Dashboard → SQL Editor, run each file in order:
#   supabase/migrations/20240001000000_enums.sql
#   supabase/migrations/20240002000000_profiles.sql
#   supabase/migrations/20240003000000_item_reports.sql
#   supabase/migrations/20240004000000_search.sql
#   supabase/migrations/20240005000000_item_matches.sql
#   supabase/migrations/20240006000000_claims.sql
#   supabase/migrations/20240007000000_notifications.sql
#   supabase/migrations/20240008000000_moderation.sql

# 4. Deploy Edge Functions (requires Supabase CLI)
supabase functions deploy create-profile
supabase functions deploy compute-matches
supabase functions deploy approve-claim
supabase functions deploy reject-claim
supabase functions deploy dispute-claim
supabase functions deploy resolve-dispute
supabase functions deploy moderate-action

# 5. Configure Auth webhook
# Supabase Dashboard → Auth → Hooks
# Add hook: event = user.created → Function = create-profile

# 6. Create Storage buckets
# Supabase Dashboard → Storage:
#   avatars        → Public
#   report-images  → Public
#   claim-evidence → Private

# 7. Run the app
flutter run
```

See [docs/setup.md](docs/setup.md) for the full step-by-step guide including screenshots and troubleshooting.

---

## Running Tests

```bash
flutter test                    # all tests
flutter test test/features/     # unit + widget tests only
flutter test test/security/     # security validation tests only
```

---

## Build Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Project Structure

```
lib/
├── main.dart                         # App entry point, ProviderScope + Supabase init
├── app.dart                          # MaterialApp.router + GoRouter setup
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # Bucket names, max sizes, pagination limits
│   │   └── supabase_constants.dart   # Table names, Edge Function names
│   ├── errors/
│   │   ├── app_exception.dart        # Typed exception sealed class hierarchy
│   │   └── failure.dart              # Failure sealed class (domain layer)
│   ├── services/
│   │   ├── supabase_service.dart     # Supabase singleton initialisation
│   │   └── storage_service.dart      # Upload / download helpers
│   ├── theme/
│   │   ├── app_theme.dart            # ThemeData (blue #1565C0, amber #FFB300)
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── utils/
│   │   ├── validators.dart           # Form field validators
│   │   └── image_utils.dart          # Compression helpers
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── error_view.dart
│       ├── loading_overlay.dart
│       ├── empty_state_view.dart
│       └── cached_network_image_widget.dart
├── features/
│   ├── auth/                         # Login, register, email verification, forgot password
│   ├── claims/                       # Submit, view, approve/reject/dispute claims
│   ├── matches/                      # Automatic similarity matches surface per report
│   ├── moderation/                   # Moderator queue, ban/warn/delete actions, audit log
│   ├── notifications/                # In-app notification list with real-time updates
│   ├── profile/                      # View & edit user profile, avatar upload
│   ├── reports/                      # Feed, create, edit, detail view for lost/found reports
│   ├── search/                       # Full-text search with category/type/date filters
│   └── shell/                        # ScaffoldWithBottomNav wrapping authenticated screens
└── router/
    ├── app_router.dart               # GoRouter definition and redirect logic
    └── route_guards.dart             # Auth guard + moderator guard
```

Each feature follows the same three-layer layout:

```
features/<name>/
├── data/           # Repository — wraps Supabase calls, maps to domain models
├── domain/         # Models (Freezed) + Riverpod providers
└── presentation/   # Screens and widgets
```

---

## Database Schema

| Table | Description |
|---|---|
| `profiles` | One row per auth user; stores display name, avatar, bio, moderator/ban flags |
| `item_reports` | Core lost/found reports with title, description, category, images, status |
| `claims` | Ownership claims submitted against a report; includes private evidence images |
| `item_matches` | Auto-computed similarity pairs linking a lost report to a found report |
| `notifications` | Per-user in-app notification inbox; append-only via Edge Function / trigger |
| `flags` | User-submitted moderation flags on reports or claims |
| `audit_logs` | Append-only log of every moderator action; no UPDATE or DELETE policies |

RLS is **enabled and forced** on all seven tables. Policy summaries are in [docs/setup.md](docs/setup.md).

---

## Security Notes

- RLS is enabled (`ENABLE ROW LEVEL SECURITY`) **and** forced (`FORCE ROW LEVEL SECURITY`) on every table — even for the `postgres` superuser in application queries.
- The Supabase service-role key never touches the Flutter app. It lives only inside Deno Edge Function environment variables.
- All sensitive status transitions (approve claim, reject claim, dispute, resolve dispute, moderate action) are gated behind Edge Functions that re-verify the caller's JWT before acting.
- Evidence images are stored in a **private** bucket. Downloads require an authenticated SDK call with a valid JWT — no plain URLs exist for evidence files.
- `audit_logs` has no UPDATE or DELETE RLS policies. Rows can only be inserted by the service role (Edge Functions), making the log tamper-evident.
- Environment secrets (Supabase URL + anon key) are compiled in via Envied, which obfuscates values at build time and prevents extraction from `strings` on the APK.

---

## Known Limitations (MVP)

- **No push notifications** — notifications are in-app only; the device must have the app open to receive them in real time.
- **Location is free-text** — no map view. `latitude`/`longitude` columns exist in the schema but are reserved for a future map phase.
- **Android is the primary target** — iOS builds are untested; the app is not submitted to any store.
