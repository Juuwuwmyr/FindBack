# FindBack — Implementation Task List
**Version:** 1.1  
**Phase:** 1 — Blueprint  
**Status:** Decisions Locked

## Locked Decisions
| Decision | Choice |
|---|---|
| Color theme | Blue `#1565C0` primary · White `#FFFFFF` background · Amber `#FFB300` accent · Light mode only |
| Location | Free-text only — no GPS, no map API |
| Evidence image access | Auth header download (`supabase.storage.download()`) — no signed URLs |
| App name / bundle ID | `FindBack` · `com.findback.app` |
| Supabase project | Existing — credentials via `.env` |
| Match algorithm | Fixed (category 40%, text 40%, date 10%, location 10%; threshold 0.45) |
| Claim approval | Reporter-first; disputes escalate to moderator |

---

Tasks are ordered by dependency. A task may not begin until all tasks it depends on are marked complete. Each task includes the files to create or modify, the acceptance test, and the relevant requirements/design references.

---

## Phase 2 — Flutter Project Setup, Theme, Navigation

### TASK-001: Initialize Flutter project
**Depends on:** nothing  
**Files to create:**
- `pubspec.yaml` (exact versions from design.md §12)
- `analysis_options.yaml` (flutter_lints + custom rules)
- `.gitignore`
- `.env.example`
- `android/app/build.gradle` (minSdk 21, targetSdk 34)

**Steps:**
1. `flutter create findback --org com.findback --platforms android,ios`
2. Replace `pubspec.yaml` with pinned dependencies from design.md §12.
3. Run `flutter pub get`.
4. Add `analysis_options.yaml` with `flutter_lints` and `avoid_print`, `prefer_const_constructors` rules.

**Acceptance:** `flutter analyze` passes with zero errors. `flutter build apk --debug` succeeds.

---

### TASK-002: Configure environment variables (envied)
**Depends on:** TASK-001  
**Files to create:**
- `lib/core/constants/env.dart` (envied annotated class)
- `lib/core/constants/env.g.dart` (generated — do not commit)
- `.env` (local, gitignored)
- `.env.example` (committed template)

**Steps:**
1. Add `.env` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
2. Create `Env` class with `@Envied(obfuscate: true)`.
3. Run `flutter pub run build_runner build`.

**Acceptance:** `Env.supabaseUrl` and `Env.supabaseAnonKey` return correct values at runtime. `.env` is listed in `.gitignore` and not committed.

---

### TASK-003: Initialize Supabase service
**Depends on:** TASK-002  
**Files to create:**
- `lib/core/services/supabase_service.dart`
- `lib/main.dart` (calls `SupabaseService.initialize()` before `runApp`)

**Steps:**
1. Call `Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey)` in `main()`.
2. Expose `Supabase.instance.client` via a `supabaseClientProvider` (plain `Provider`).

**Acceptance:** App starts without exception. `Supabase.instance.client` is non-null in a widget test using a mock initializer.

---

### TASK-004: Define app theme and global widgets
**Depends on:** TASK-001  
**Files to create:**
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/widgets/app_button.dart`
- `lib/core/widgets/app_text_field.dart`
- `lib/core/widgets/error_view.dart`
- `lib/core/widgets/loading_overlay.dart`
- `lib/core/widgets/empty_state_view.dart`
- `lib/core/widgets/cached_network_image_widget.dart`

**Steps:**
1. Define a `ColorScheme` using Material 3 with the following locked palette:
   - **Primary:** `#1565C0` (deep blue) — main actions, app bar, active nav
   - **On-Primary:** `#FFFFFF` (white)
   - **Secondary/Accent:** `#FFB300` (amber) — badges, highlights, CTAs
   - **Background:** `#FFFFFF` (white)
   - **Surface:** `#F5F8FF` (very light blue-tinted white)
   - **Error:** `#B00020`
   - **On-Background / On-Surface:** `#1A1A2E` (near-black with blue undertone)
   - Light mode only for MVP. Dark mode tokens reserved but not implemented.
2. Define text styles using `GoogleFonts` or system font.
3. Implement `AppButton` (primary, secondary, destructive variants).
4. Implement `AppTextField` with label, hint, error text, and obscure support.
5. Implement `ErrorView(message, onRetry)` and `EmptyStateView(message, icon)`.
6. Implement `LoadingOverlay` that stacks a `CircularProgressIndicator` over any child.
7. Implement `CachedNetworkImageWidget(url, fit, placeholder)`.

**Acceptance:** Widget tests confirm each widget renders in loading, error, and data states. Primary blue (`#1565C0`) on white passes WCAG AA contrast (ratio ≈ 7.2:1 ✓). Amber (`#FFB300`) used only on dark backgrounds or as icon/badge color — not as text background.

---

### TASK-005: Set up GoRouter and bottom navigation shell
**Depends on:** TASK-003, TASK-004  
**Files to create:**
- `lib/router/app_router.dart`
- `lib/router/route_guards.dart`
- `lib/app.dart`
- Stub screen files for every route (empty `Scaffold` with route name as title)

**Steps:**
1. Define all routes from design.md §3 as `GoRoute` entries.
2. Implement `authGuard` redirect: unauthenticated → `/auth/login`.
3. Implement `moderatorGuard` redirect: non-moderator → `/feed`.
4. Create `ScaffoldWithBottomNav` shell with 4 tabs: Feed, Search, Notifications, Profile.
5. Register `ProviderScope` wrapping `MaterialApp.router` in `app.dart`.

**Acceptance:** Navigating to a guarded route when unauthenticated redirects to `/auth/login`. Deep-linking to `/report/:id` works from a cold start. Bottom nav tabs switch without losing scroll position (using `StatefulShellRoute`).

---

## Phase 3 — Supabase Backend: Migrations, Auth, Profiles

### TASK-006: Create PostgreSQL enums migration
**Depends on:** TASK-003  
**Files to create:**
- `supabase/migrations/20240001_enums.sql`

**Content:** All `CREATE TYPE` statements from design.md §6 (Enums section).

**Acceptance:** Migration runs on a fresh Supabase project without error. `SELECT enum_range(NULL::report_type)` returns expected values.

---

### TASK-007: Create profiles table migration
**Depends on:** TASK-006  
**Files to create:**
- `supabase/migrations/20240002_profiles.sql`

**Content:**
1. `CREATE TABLE profiles` with all columns from design.md §6.
2. `ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;`
3. `ALTER TABLE profiles FORCE ROW LEVEL SECURITY;`
4. All four RLS policies from design.md §8 (profiles section).
5. `updated_at` trigger: `CREATE TRIGGER set_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);`

**Acceptance:** A test user can read their own profile. A test user cannot set `is_moderator = true` via a direct UPDATE (attempt returns RLS violation error).

---

### TASK-008: Create profile auto-creation Edge Function
**Depends on:** TASK-007  
**Files to create:**
- `supabase/functions/create-profile/index.ts`

**Steps:**
1. Listen for `auth.users` INSERT via Supabase Auth webhook (configured in Supabase dashboard).
2. Insert a `profiles` row using `supabaseAdmin` (service-role client).
3. Set `display_name` from user metadata if present, otherwise empty string.

**Acceptance:** Registering a new user via the Supabase dashboard auto-creates a `profiles` row. Attempting to create a duplicate profile (same `id`) is a no-op (ON CONFLICT DO NOTHING).

---

### TASK-009: Authentication repository and providers
**Depends on:** TASK-008  
**Files to create:**
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/domain/auth_state.dart`
- `lib/features/auth/domain/auth_provider.dart`

**Steps:**
1. `AuthRepository` wraps `supabase.auth` methods: `signUp`, `signInWithPassword`, `signOut`, `resetPassword`, `resendVerificationEmail`.
2. Maps `AuthException` from Supabase to `AppException` subtypes.
3. `authStateProvider` is a `StreamProvider` wrapping `supabase.auth.onAuthStateChange`.
4. `currentUserProvider` derives `User?` from auth state.

**Acceptance:** Unit tests (with mocked Supabase client) confirm sign-in returns a user, sign-out returns null, and an incorrect password throws `AuthException`.

---

### TASK-010: Authentication screens
**Depends on:** TASK-009, TASK-005  
**Files to create:**
- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/auth/presentation/register_screen.dart`
- `lib/features/auth/presentation/forgot_password_screen.dart`
- `lib/features/auth/presentation/verify_email_screen.dart`

**Steps:**
1. `LoginScreen`: email + password fields, "Forgot password?" link, submit button, error display.
2. `RegisterScreen`: email + password + confirm password, display name field, terms checkbox.
3. `ForgotPasswordScreen`: email field, sends reset link, shows confirmation.
4. `VerifyEmailScreen`: informs user to check email, "Resend email" button, auto-redirects when verified.
5. All screens use `AppTextField`, `AppButton`, `LoadingOverlay`.
6. Form validation: email format, password ≥ 8 chars, passwords match.

**Acceptance:**
- Widget test: submitting login form with blank fields shows validation errors.
- Widget test: successful login navigates to `/feed`.
- Widget test: unverified user sees `VerifyEmailScreen` instead of feed.

---

### TASK-011: Profile repository and provider
**Depends on:** TASK-007, TASK-009  
**Files to create:**
- `lib/features/profile/data/profile_repository.dart`
- `lib/features/profile/domain/profile_model.dart` (freezed)
- `lib/features/profile/domain/profile_provider.dart`

**Steps:**
1. `ProfileModel` as a `@freezed` class with `fromJson`/`toJson`.
2. `ProfileRepository.fetchProfile(userId)` — SELECT from `profiles`.
3. `ProfileRepository.updateProfile(...)` — UPDATE own profile (allowed columns only).
4. `ProfileRepository.uploadAvatar(file)` — uploads to `avatars/{uid}/{uuid}.jpg`, returns public URL.
5. `profileProvider` is a `FutureProvider.family<ProfileModel, String>`.
6. `ownProfileProvider` watches `currentUserProvider` and re-fetches on auth change.

**Acceptance:**
- Unit test: `fetchProfile` returns a `ProfileModel` from a mocked response.
- Unit test: `updateProfile` with `is_moderator` field throws `PermissionException`.
- Integration test: editing display name persists to Supabase and re-fetched profile reflects the change.

---

### TASK-012: Profile screens
**Depends on:** TASK-011, TASK-005  
**Files to create:**
- `lib/features/profile/presentation/profile_screen.dart`
- `lib/features/profile/presentation/edit_profile_screen.dart`

**Steps:**
1. `ProfileScreen(userId)`: avatar, display name, bio, location, public reports list (uses `reportsFeedProvider` filtered by user).
2. "Edit Profile" button visible only for own profile.
3. `EditProfileScreen`: avatar picker (camera/gallery), display name, bio, location fields.
4. Avatar upload shows progress indicator, updates avatar URL on success.
5. Save button disabled while unchanged.

**Acceptance:**
- Tapping "Edit Profile" on own profile navigates to `EditProfileScreen`.
- Uploading avatar updates the displayed image without full page reload.
- Attempting to visit edit profile for another user's ID redirects to their view-only profile.

---

## Phase 4 — Reports, Uploads, Feed

### TASK-013: Create item_reports table migration
**Depends on:** TASK-007  
**Files to create:**
- `supabase/migrations/20240003_item_reports.sql`

**Content:**
1. `CREATE TABLE item_reports` with all columns from design.md §6.
2. `search_vector` generated column: `to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,''))`.
3. `ENABLE ROW LEVEL SECURITY` + `FORCE ROW LEVEL SECURITY`.
4. All RLS policies from design.md §8 (item_reports section).
5. All indexes from design.md §6 (Indexes section) that apply to `item_reports`.
6. `moddatetime` trigger for `updated_at`.

**Acceptance:** Migration runs cleanly. A SELECT by an anonymous user returns only ACTIVE/RESOLVED non-deleted reports. A user cannot UPDATE the `status` column directly (returns RLS error).

---

### TASK-014: Storage service and image upload helpers
**Depends on:** TASK-003  
**Files to create:**
- `lib/core/services/storage_service.dart`
- `lib/core/utils/image_utils.dart`

**Steps:**
1. `StorageService.uploadReportImage(reportId, file)` → uploads to `report-images/{reportId}/{uuid}.jpg`.
2. `StorageService.uploadEvidenceImage(claimId, file)` → uploads to `claim-evidence/{claimId}/{uuid}.jpg`.
3. `StorageService.uploadAvatar(userId, file)` → uploads to `avatars/{userId}/{uuid}.jpg`.
4. `ImageUtils.compressImage(file)` → uses `flutter_image_compress` to reduce to ≤ 800KB, max 1920px.
5. `ImageUtils.pickFromGallery()` and `ImageUtils.pickFromCamera()` wrappers.
6. All upload methods return the public/signed URL on success.

**Acceptance:**
- Unit test (mocked storage): upload returns a non-empty URL string.
- Unit test: `compressImage` on a 6 MB JPEG returns a file ≤ 800 KB.
- A user cannot call `uploadEvidenceImage` for a claim they don't own (storage RLS rejects it).

---

### TASK-015: Reports repository and providers
**Depends on:** TASK-013, TASK-014  
**Files to create:**
- `lib/features/reports/data/reports_repository.dart`
- `lib/features/reports/domain/item_report_model.dart` (freezed)
- `lib/features/reports/domain/reports_provider.dart`

**Steps:**
1. `ItemReportModel` as `@freezed` class with `fromJson`/`toJson`. All enums serialized as strings.
2. `ReportsRepository.fetchFeed({cursor, limit})` — keyset pagination on `(created_at DESC, id)`.
3. `ReportsRepository.fetchReport(id)` — single report by ID.
4. `ReportsRepository.createReport(...)` — INSERT, then upload images, then UPDATE `image_urls`.
5. `ReportsRepository.updateReport(id, ...)` — UPDATE allowed fields only.
6. `ReportsRepository.softDeleteReport(id)` — sets `deleted_at = now()`.
7. `reportsFeedProvider` — `AsyncNotifier<List<ItemReportModel>>` with `loadNextPage()`.
8. `reportDetailProvider` — `FutureProvider.family<ItemReportModel, String>`.

**Acceptance:**
- Unit test: `fetchFeed` with limit=20 returns ≤ 20 items sorted by `created_at DESC`.
- Unit test: `createReport` with missing required field throws `ValidationException`.
- Integration test: creating a report and fetching it by ID returns matching data.

---

### TASK-016: Create report screen
**Depends on:** TASK-015, TASK-005  
**Files to create:**
- `lib/features/reports/presentation/create_report_screen.dart`

**Steps:**
1. Multi-step form: Step 1 (type, category, title), Step 2 (description, date, location), Step 3 (images, reward).
2. Image picker: up to 5 images, shows thumbnails with remove button.
3. Date picker: calendar widget, no future dates.
4. Location: free-text field only (e.g. "Makati City, Metro Manila"). No GPS button — free-text only per Q2 decision.
5. Submit: validates all required fields, creates report, shows success with navigation to detail.
6. Loading state disables submit button and shows spinner.

**Acceptance:**
- Submitting without required fields highlights each invalid field.
- Submitting a valid form creates the report and navigates to its detail screen.
- Images upload asynchronously; a progress bar is shown per image.
- A guest user tapping "Create Report" is redirected to login.

---

### TASK-017: Feed screen
**Depends on:** TASK-015, TASK-005  
**Files to create:**
- `lib/features/reports/presentation/feed_screen.dart`
- `lib/features/reports/presentation/widgets/report_card.dart`

**Steps:**
1. `FeedScreen` uses `PagedListView` from `infinite_scroll_pagination`.
2. `ReportCard` shows: type badge (LOST/FOUND), category icon, title, location, date, thumbnail.
3. Pull-to-refresh calls `reportsFeedProvider.refresh()`.
4. Filter chip row at the top: LOST / FOUND / All, with active chip highlighted.
5. Offline banner when `Connectivity` reports no internet.
6. Skeleton shimmer while first page loads.

**Acceptance:**
- 20 items load on first visit. Scrolling to the bottom loads the next 20.
- Pull-to-refresh reloads from the beginning.
- The offline banner appears when device has no internet.
- Tapping a card navigates to `ReportDetailScreen`.

---

### TASK-018: Report detail screen
**Depends on:** TASK-015, TASK-005  
**Files to create:**
- `lib/features/reports/presentation/report_detail_screen.dart`

**Steps:**
1. Shows all report fields: title, description, category, type badge, date, location, images (swipeable gallery), reward info.
2. "Submit a Claim" button visible if: authenticated, not the reporter, report is ACTIVE.
3. "Edit Report" and "Close Report" buttons visible to reporter only.
4. "Possible Matches" section (collapsed by default) — populated from `matchesForReportProvider` (Phase 5).
5. Claims section visible to reporter: count of pending claims, "View Claims" button.
6. Share button (deep link to report URL).
7. Flag button (authenticated users only).

**Acceptance:**
- Reporter sees "Edit" and "Close" buttons; other users do not.
- Unauthenticated user sees "Submit a Claim" button but tapping it redirects to login.
- Sharing generates a valid deep link.

---

### TASK-019: Edit report screen
**Depends on:** TASK-015, TASK-016  
**Files to create:**
- `lib/features/reports/presentation/edit_report_screen.dart`

**Steps:**
1. Pre-populates form with existing report data.
2. Only allows editing: title, description, category, date_of_incident, location_text, images, reward fields.
3. Adding/removing images updates `image_urls` in storage and database.
4. Save button disabled until a change is made.

**Acceptance:**
- Changes save and detail screen reflects updated data immediately (provider invalidated).
- Attempting to change `status` via the edit form is not possible (field not present).
- Navigating away without saving prompts a discard confirmation dialog.

---

## Phase 5 — Search and Matching

### TASK-020: Create search infrastructure migration
**Depends on:** TASK-013  
**Files to create:**
- `supabase/migrations/20240004_search.sql`

**Content:**
1. Enable `pg_trgm` extension: `CREATE EXTENSION IF NOT EXISTS pg_trgm;`.
2. GIN index on `search_vector` (already in TASK-013, confirm here).
3. GIN trigram index on `location_text`.
4. Create `search_reports` PostgreSQL function:
```sql
CREATE OR REPLACE FUNCTION search_reports(
  query text,
  p_type report_type DEFAULT NULL,
  p_category item_category DEFAULT NULL,
  p_date_from date DEFAULT NULL,
  p_date_to date DEFAULT NULL,
  p_location text DEFAULT NULL,
  p_cursor_created_at timestamptz DEFAULT NULL,
  p_cursor_id uuid DEFAULT NULL,
  p_limit int DEFAULT 20
) RETURNS SETOF item_reports ...
```

**Acceptance:** Calling `search_reports('red backpack')` returns reports with those words in title or description. Calling with `p_type = 'LOST'` excludes FOUND reports.

---

### TASK-021: Search repository and provider
**Depends on:** TASK-020  
**Files to create:**
- `lib/features/search/data/search_repository.dart`
- `lib/features/search/domain/search_filter_model.dart` (freezed)
- `lib/features/search/domain/search_provider.dart`

**Steps:**
1. `SearchFilterModel`: query, type, category, dateFrom, dateTo, locationText.
2. `SearchRepository.search(filter, cursor, limit)` calls `search_reports` RPC.
3. `searchProvider` is a `StateNotifier` holding `AsyncValue<List<ItemReportModel>>` + `SearchFilterModel`.
4. Debounce text input by 400ms before triggering search.

**Acceptance:**
- Unit test: changing filter re-triggers search with new params.
- Unit test: debounce prevents more than one call per 400ms burst.

---

### TASK-022: Search screen
**Depends on:** TASK-021, TASK-005  
**Files to create:**
- `lib/features/search/presentation/search_screen.dart`
- `lib/features/search/presentation/widgets/filter_bottom_sheet.dart`

**Steps:**
1. Search bar at top with clear button.
2. Filter icon opens `FilterBottomSheet` with type toggle, category dropdown, date range pickers, location field.
3. Results list reuses `ReportCard` from TASK-017.
4. "No results" empty state with illustration.
5. Active filters shown as dismissible chips below the search bar.

**Acceptance:**
- Typing in the search bar triggers search after 400ms idle.
- Applied filters are shown as chips; removing a chip clears that filter.
- Clearing the search bar returns to an empty state (not a previous search result).

---

### TASK-023: Create item_matches table migration
**Depends on:** TASK-013  
**Files to create:**
- `supabase/migrations/20240005_item_matches.sql`

**Content:**
1. `CREATE TABLE item_matches` with all columns from design.md §6.
2. RLS policies from design.md §8 (item_matches section).
3. Indexes: `idx_matches_lost`, `idx_matches_found`, `idx_matches_unique_pair`.

**Acceptance:** Migration runs cleanly. A user cannot INSERT directly into `item_matches` (RLS INSERT = false). A reporter can read matches for their own reports.

---

### TASK-024: Match computation Edge Function
**Depends on:** TASK-023  
**Files to create:**
- `supabase/functions/compute-matches/index.ts`

**Algorithm:**
1. Triggered by DB webhook on `item_reports` INSERT or UPDATE (title/description/category/date_of_incident changed).
2. Fetch the triggering report.
3. Query opposite-type ACTIVE reports.
4. For each candidate, compute:
   - Category match: `category == candidate.category ? 0.4 : 0`
   - Text similarity: `similarity(title || description, candidate.title || description)` × 0.4
   - Date proximity: `max(0, 1 - abs(date_diff_days) / 14) * 0.1`
   - Location similarity: `similarity(location_text, candidate.location_text)` × 0.1
5. Sum score. If ≥ 0.45 and no existing match, INSERT into `item_matches`.
6. If existing match score changed by > 0.05, UPDATE score.

**Acceptance:**
- Integration test: submitting a FOUND report for a known LOST report with the same category and similar text produces a match with score ≥ 0.45.
- Match is NOT created if score < 0.45.
- Duplicate match pairs are not created (unique index prevents it).

---

### TASK-025: Matches repository and widget
**Depends on:** TASK-023, TASK-024  
**Files to create:**
- `lib/features/matches/data/matches_repository.dart`
- `lib/features/matches/domain/item_match_model.dart` (freezed)
- `lib/features/matches/domain/matches_provider.dart`
- `lib/features/matches/presentation/matches_section_widget.dart`

**Steps:**
1. `MatchesRepository.fetchMatchesForReport(reportId)` — returns PENDING matches with joined opposite report data.
2. `MatchesRepository.dismissMatch(matchId)` — UPDATE status to DISMISSED.
3. `matchesForReportProvider` — `FutureProvider.family`.
4. `MatchesSectionWidget(reportId)`: expandable section listing match cards with score badge and "Dismiss" button.

**Acceptance:**
- Matches section shows on reporter's own report detail screen.
- Dismissing a match removes it from the list immediately (optimistic update).
- Non-reporters do not see the matches section.

---

## Phase 6 — Claims, Evidence, Review

### TASK-026: Create claims table migration
**Depends on:** TASK-013  
**Files to create:**
- `supabase/migrations/20240006_claims.sql`

**Content:**
1. `CREATE TABLE claims` with all columns from design.md §6.
2. RLS policies from design.md §8 (claims section).
3. Indexes including partial unique index `idx_claims_one_active_per_user`.
4. `moddatetime` trigger for `updated_at`.

**Acceptance:**
- Inserting two PENDING claims from the same user on the same report fails with a unique constraint violation.
- The reporter can SELECT all claims on their report.
- A third user cannot SELECT any claims they are not party to.

---

### TASK-027: Claim Edge Functions
**Depends on:** TASK-026  
**Files to create:**
- `supabase/functions/approve-claim/index.ts`
- `supabase/functions/reject-claim/index.ts`
- `supabase/functions/dispute-claim/index.ts`
- `supabase/functions/resolve-dispute/index.ts`

**For each function:**
1. Authenticate caller: `supabase.auth.getUser(req.headers.get('Authorization'))`.
2. Validate role (reporter / claimant / moderator as appropriate).
3. Validate current claim status before transition.
4. Perform transition using `supabaseAdmin` (service role).
5. Write to `audit_logs`.
6. Insert notification row(s) for affected users.
7. Return `{ success: true }` or `{ error: "..." }` with appropriate HTTP status.

**`approve-claim` specifics:**
- Verify `caller.id == report.reporter_id`.
- Verify `caller.id != claim.claimant_id`.
- Set claim `status = APPROVED`, `reviewer_id = caller.id`, `reviewed_at = now()`.
- Set all other PENDING claims on same report to `REJECTED`.
- Set report `status = CLAIMED`.

**Acceptance:**
- Calling `approve-claim` as the claimant returns 403.
- Calling `approve-claim` on an already-APPROVED claim returns 409.
- After approval, all other PENDING claims on the report are REJECTED (verified by DB query).
- An audit log row exists for each action.

---

### TASK-028: Claims repository and providers
**Depends on:** TASK-027  
**Files to create:**
- `lib/features/claims/data/claims_repository.dart`
- `lib/features/claims/domain/claim_model.dart` (freezed)
- `lib/features/claims/domain/claims_provider.dart`

**Steps:**
1. `ClaimModel` as `@freezed` class.
2. `ClaimsRepository.submitClaim(reportId, description, evidenceFiles, contactPref, contactDetail)`:
   a. INSERT claim row (status PENDING, no evidence URLs yet).
   b. Upload evidence images to `claim-evidence/{claimId}/`.
   c. UPDATE claim `evidence_image_urls`.
3. `ClaimsRepository.withdrawClaim(claimId)` — UPDATE status to WITHDRAWN (direct client call; RLS allows).
4. `ClaimsRepository.approveClaim(claimId)` — calls `approve-claim` Edge Function.
5. `ClaimsRepository.rejectClaim(claimId)` — calls `reject-claim` Edge Function.
6. `ClaimsRepository.disputeClaim(claimId)` — calls `dispute-claim` Edge Function.
7. `ClaimsRepository.fetchClaimsForReport(reportId)` — SELECT with joined claimant profile.
8. `ClaimsRepository.fetchMyClaim(reportId)` — SELECT own claim.
9. `claimsForReportProvider` — `FutureProvider.family`.
10. `myClaimForReportProvider` — `FutureProvider.family`.

**Acceptance:**
- Unit test: `submitClaim` without evidence images throws `ValidationException`.
- Unit test: `approveClaim` calls the correct Edge Function URL with the correct auth header.
- Integration test: submitting a claim, then fetching claims for that report, shows the claim in PENDING status.

---

### TASK-029: Submit claim screen
**Depends on:** TASK-028, TASK-005  
**Files to create:**
- `lib/features/claims/presentation/submit_claim_screen.dart`

**Steps:**
1. Description text area (required, ≤ 1000 chars with counter).
2. Evidence image picker: 1–5 images required, shows thumbnails.
3. Contact preference selector (IN_APP / EMAIL / PHONE).
4. Contact detail field (shown/required when EMAIL or PHONE selected).
5. Submit button with loading state.
6. Success: navigates back to report detail with a snackbar "Claim submitted."

**Acceptance:**
- Cannot submit without at least 1 evidence image.
- Cannot submit without description.
- Contact detail field appears only when EMAIL or PHONE is selected.
- Submitting a duplicate claim (user already has an active claim) shows a clear error.

---

### TASK-030: Claim detail and claims list screens
**Depends on:** TASK-028, TASK-005  
**Files to create:**
- `lib/features/claims/presentation/claim_detail_screen.dart`
- `lib/features/claims/presentation/claims_list_screen.dart`

**Steps:**
1. `ClaimsListScreen(reportId)`: shows all claims on a report (reporter only). Each row: claimant avatar/name, status badge, "View" button.
2. `ClaimDetailScreen(claimId)`:
   - For reporter: shows description, evidence images (with auth), contact info, Approve / Reject buttons.
   - For claimant: shows own description, evidence, status, "Withdraw" button (if PENDING), "Dispute" button (if REJECTED, only once).
3. Evidence images loaded via `supabase.storage.from('claim-evidence').download(path)` with the user's JWT (auth header pattern — no signed URLs per Q3 decision). Decoded bytes rendered via `Image.memory`.
4. Status badges color-coded: PENDING=yellow, APPROVED=green, REJECTED=red, WITHDRAWN=grey, DISPUTED=orange.

**Acceptance:**
- Reporter sees Approve/Reject buttons; claimant does not.
- Claimant cannot navigate to another user's claim detail (route guard checks ownership).
- Evidence images display correctly (not broken) for both reporter and claimant.
- Withdrawing a claim updates status immediately and disables the withdraw button.

---

## Phase 7 — Notifications, Moderation, Audit

### TASK-031: Create notifications table migration
**Depends on:** TASK-007  
**Files to create:**
- `supabase/migrations/20240007_notifications.sql`

**Content:**
1. `CREATE TABLE notifications` from design.md §6.
2. RLS policies from design.md §8 (notifications section).
3. Index `idx_notifications_user_unread`.

**Acceptance:** A user can SELECT their own notifications. A user cannot SELECT another user's notifications (RLS verified). Direct INSERT by a client returns RLS error.

---

### TASK-032: Notifications repository and provider
**Depends on:** TASK-031  
**Files to create:**
- `lib/features/notifications/data/notifications_repository.dart`
- `lib/features/notifications/domain/notification_model.dart` (freezed)
- `lib/features/notifications/domain/notifications_provider.dart`

**Steps:**
1. `NotificationsRepository.fetchNotifications()` — SELECT own, ordered by `created_at DESC`, limit 50.
2. `NotificationsRepository.markAsRead(notificationId)` — UPDATE `is_read = true`.
3. `NotificationsRepository.markAllRead()` — UPDATE WHERE `user_id = auth.uid()`.
4. `notificationsProvider` — `AsyncNotifier<List<NotificationModel>>`.
5. `unreadCountProvider` — derived `Provider<int>` counting unread items from `notificationsProvider`.
6. Real-time: subscribe to `notifications` table changes via `supabase.from('notifications').stream(...)` filtered by `user_id`.

**Acceptance:**
- Unread count badge on bottom nav updates immediately when a new notification arrives via real-time subscription.
- Marking all as read sets badge to 0.
- Unit test: `fetchNotifications` maps payload JSON to `NotificationModel` correctly.

---

### TASK-033: Notifications screen
**Depends on:** TASK-032, TASK-005  
**Files to create:**
- `lib/features/notifications/presentation/notifications_screen.dart`
- `lib/features/notifications/presentation/widgets/notification_tile.dart`

**Steps:**
1. List of `NotificationTile` items: icon (by type), title, body, relative time, unread dot.
2. "Mark all as read" button in AppBar.
3. Tapping a notification marks it read and navigates to the relevant screen (using `payload` to route).
4. Empty state: "No notifications yet."
5. Pull-to-refresh.

**Acceptance:**
- Unread notifications have a distinct visual indicator.
- Tapping a NEW_CLAIM notification navigates to the claims list for the relevant report.
- Tapping a CLAIM_APPROVED notification navigates to the claim detail.

---

### TASK-034: Create flags and audit_logs table migration
**Depends on:** TASK-007  
**Files to create:**
- `supabase/migrations/20240008_moderation.sql`

**Content:**
1. `CREATE TABLE flags` from design.md §6.
2. `CREATE TABLE audit_logs` from design.md §6.
3. RLS policies from design.md §8 for both tables.

**Acceptance:** A moderator can SELECT all unresolved flags. A regular user cannot SELECT `audit_logs`. No client can INSERT into `audit_logs` (RLS INSERT = false).

---

### TASK-035: Moderation Edge Function
**Depends on:** TASK-034  
**Files to create:**
- `supabase/functions/moderate-action/index.ts`

**Supported actions:** `REMOVE_REPORT`, `REMOVE_CLAIM`, `WARN_USER`, `BAN_USER`, `RESOLVE_FLAG`.

**For each action:**
1. Authenticate caller and verify `is_moderator = true`.
2. Perform action using service-role client.
3. Write to `audit_logs`.
4. Send notification to affected user.

**Acceptance:**
- Calling `moderate-action` as a non-moderator returns 403.
- Banning a user sets `is_banned = true` in `profiles`.
- Every action produces an `audit_logs` row with full detail.

---

### TASK-036: Moderation repository and screens
**Depends on:** TASK-035, TASK-005  
**Files to create:**
- `lib/features/moderation/data/moderation_repository.dart`
- `lib/features/moderation/domain/moderation_provider.dart`
- `lib/features/moderation/presentation/moderation_queue_screen.dart`
- `lib/features/moderation/presentation/moderation_action_sheet.dart`

**Steps:**
1. `ModerationRepository.fetchFlaggedItems()` — SELECT from `flags` (unresolved), joined with target.
2. `ModerationRepository.performAction(action, targetType, targetId, reason)` — calls `moderate-action` Edge Function.
3. `ModerationQueueScreen`: list of flagged items with type indicator and "Take Action" button.
4. `ModerationActionSheet`: bottom sheet with action options (Remove, Warn, Ban) and reason field.
5. Route guard: only moderators can access `/moderation`.

**Acceptance:**
- Non-moderator cannot navigate to moderation queue (redirected by route guard).
- Taking a moderation action removes the item from the queue and shows a success snackbar.
- Flag count on the moderation queue badge updates after actions.

---

## Phase 8 — Testing, Security Verification, Documentation

### TASK-037: Unit tests for repositories
**Depends on:** TASK-009, TASK-011, TASK-015, TASK-021, TASK-028, TASK-032  
**Files to create:**
- `test/features/auth/auth_repository_test.dart`
- `test/features/profile/profile_repository_test.dart`
- `test/features/reports/reports_repository_test.dart`
- `test/features/search/search_repository_test.dart`
- `test/features/claims/claims_repository_test.dart`
- `test/features/notifications/notifications_repository_test.dart`

**Coverage target:** All public repository methods, both success and error paths.

**Acceptance:** `flutter test test/features/` passes with zero failures.

---

### TASK-038: Widget tests for screens
**Depends on:** TASK-010, TASK-012, TASK-016, TASK-017, TASK-018, TASK-029, TASK-030, TASK-033  
**Files to create:**
- `test/features/auth/login_screen_test.dart`
- `test/features/reports/feed_screen_test.dart`
- `test/features/reports/create_report_screen_test.dart`
- `test/features/claims/submit_claim_screen_test.dart`

**Each widget test must cover:** loading state, empty state, error state with retry, and one happy-path interaction.

**Acceptance:** `flutter test test/features/` passes with zero failures.

---

### TASK-039: Security verification tests
**Depends on:** TASK-026, TASK-027, TASK-031, TASK-034  
**Files to create:**
- `test/security/rls_policies_test.dart` (integration test using test Supabase project)

**Tests to include:**
1. A user cannot set `is_moderator = true` on their own profile.
2. A user cannot INSERT into `audit_logs`.
3. A user cannot INSERT into `notifications`.
4. A user cannot SELECT another user's notifications.
5. A user cannot SELECT another user's claim evidence (storage test).
6. A non-reporter cannot approve a claim (Edge Function returns 403).
7. A user cannot submit two active claims on the same report (DB constraint test).
8. A banned user cannot INSERT a new report (RLS check).
9. A non-moderator cannot access the `moderate-action` Edge Function.

**Acceptance:** All 9 security tests pass. Any failure is a blocker for release.

---

### TASK-040: README and setup documentation
**Depends on:** all previous tasks  
**Files to create:**
- `README.md`
- `CONTRIBUTING.md`
- `docs/setup.md`

**README must include:**
1. Project overview and screenshots placeholder.
2. Prerequisites (Flutter SDK version, Dart version, Supabase CLI version).
3. Environment setup steps (`.env` file, Supabase project creation).
4. Running migrations: `supabase db push`.
5. Deploying Edge Functions: `supabase functions deploy`.
6. Running the app: `flutter run`.
7. Running tests: `flutter test`.
8. Android release build: `flutter build apk --release`.
9. Architecture overview (brief, links to design.md).
10. Security notes.

**Acceptance:** A developer following only the README can run the app locally from scratch in under 30 minutes.

---

## Dependency Graph Summary

```
TASK-001 (Flutter init)
  └── TASK-002 (envied)
        └── TASK-003 (Supabase init)
              ├── TASK-005 (Router/Nav) ← also needs TASK-004
              ├── TASK-006 (Enums migration)
              │     └── TASK-007 (Profiles migration)
              │           ├── TASK-008 (create-profile fn)
              │           │     └── TASK-009 (Auth repo)
              │           │           ├── TASK-010 (Auth screens) ← needs TASK-005
              │           │           └── TASK-011 (Profile repo)
              │           │                 └── TASK-012 (Profile screens) ← needs TASK-005
              │           ├── TASK-013 (item_reports migration)
              │           │     ├── TASK-014 (Storage service)
              │           │     │     └── TASK-015 (Reports repo)
              │           │     │           ├── TASK-016 (Create report screen)
              │           │     │           ├── TASK-017 (Feed screen)
              │           │     │           ├── TASK-018 (Report detail screen)
              │           │     │           └── TASK-019 (Edit report screen)
              │           │     ├── TASK-020 (Search migration)
              │           │     │     └── TASK-021 (Search repo)
              │           │     │           └── TASK-022 (Search screen)
              │           │     ├── TASK-023 (item_matches migration)
              │           │     │     ├── TASK-024 (compute-matches fn)
              │           │     │     └── TASK-025 (Matches repo + widget)
              │           │     └── TASK-026 (claims migration)
              │           │           ├── TASK-027 (Claim Edge Functions)
              │           │           └── TASK-028 (Claims repo)
              │           │                 ├── TASK-029 (Submit claim screen)
              │           │                 └── TASK-030 (Claim detail/list screens)
              │           ├── TASK-031 (notifications migration)
              │           │     └── TASK-032 (Notifications repo)
              │           │           └── TASK-033 (Notifications screen)
              │           └── TASK-034 (flags + audit_logs migration)
              │                 ├── TASK-035 (moderate-action fn)
              │                 └── TASK-036 (Moderation repo + screens)
              └── TASK-004 (Theme + widgets)

TASK-037 (Unit tests)     ← after repos complete
TASK-038 (Widget tests)   ← after screens complete
TASK-039 (Security tests) ← after all migrations + Edge Functions complete
TASK-040 (README/docs)    ← after everything complete
```

---

## Milestone Summary

| Milestone | Tasks | Deliverable |
|---|---|---|
| M1 — Scaffold | 001–005 | Runnable app with navigation |
| M2 — Auth + Profiles | 006–012 | Working registration, login, profile edit |
| M3 — Reports + Feed | 013–019 | Create/view/edit reports, paginated feed |
| M4 — Search + Matching | 020–025 | Full-text search, match suggestions |
| M5 — Claims | 026–030 | Submit, review, approve, dispute claims |
| M6 — Notifications + Moderation | 031–036 | In-app notifications, moderator queue |
| M7 — Quality | 037–040 | Tests, security verification, docs |
