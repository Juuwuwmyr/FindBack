# FindBack — Setup Guide

This guide walks through every step required to go from a fresh clone to a running app. Complete the steps in order — later steps depend on earlier ones.

---

## 1. Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign in (or create a free account).
2. Click **New project**, choose your organisation, enter a project name (e.g. `findback`), set a strong database password, and pick a region close to your users.
3. Wait for provisioning to complete (about 60 seconds).
4. Once the project is ready, open **Project Settings → API**.
5. Copy two values — you will need them in the next step:
   - **Project URL** — looks like `https://xyzabcdef.supabase.co`
   - **anon / public key** — a long JWT starting with `eyJ…`

> The service-role key is **not** needed in the Flutter app. Do not put it in `.env`.

---

## 2. Configure the .env File

The project uses [Envied](https://pub.dev/packages/envied) to compile secrets into the binary. Envied reads from a `.env` file at the project root.

```bash
cp .env.example .env
```

Open `.env` and replace the placeholder values:

```
SUPABASE_URL=https://xyzabcdef.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

After editing `.env`, regenerate the Envied class so the new values are compiled in:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

The generated file `lib/core/env/env.g.dart` is listed in `.gitignore` and must never be committed.

---

## 3. Run the SQL Migrations

The database schema is split across 8 migration files under `supabase/migrations/`. They must be run in filename order because later migrations reference objects created by earlier ones.

**In Supabase Dashboard:**
1. Navigate to your project → **SQL Editor**.
2. Click **New query**.
3. Open each file locally and paste its contents, then click **Run**. Repeat for all 8 files in the order below.

| Order | File | Creates |
|---|---|---|
| 1 | `20240001000000_enums.sql` | All PostgreSQL enum types (`report_type`, `report_status`, `item_category`, `claim_status`, `contact_pref`, `match_status`, `notification_type`) |
| 2 | `20240002000000_profiles.sql` | `profiles` table, RLS policies, updated_at trigger |
| 3 | `20240003000000_item_reports.sql` | `item_reports` table, RLS policies, indexes |
| 4 | `20240004000000_search.sql` | Full-text `search_vector` column, GIN index, trigram extension |
| 5 | `20240005000000_item_matches.sql` | `item_matches` table, RLS policies, unique pair index |
| 6 | `20240006000000_claims.sql` | `claims` table, RLS policies, unique active-claim-per-user index |
| 7 | `20240007000000_notifications.sql` | `notifications` table, RLS policies, unread index |
| 8 | `20240008000000_moderation.sql` | `flags` table, `audit_logs` table, RLS policies |

> **Dependency note:** Migration 4 (search) requires the `pg_trgm` extension. The SQL file enables it automatically with `CREATE EXTENSION IF NOT EXISTS pg_trgm`. Migration 6 (claims) references both `item_reports` and `profiles`, so 2 and 3 must be done first.

After running all migrations, verify in **Table Editor** that the following tables exist: `profiles`, `item_reports`, `claims`, `item_matches`, `notifications`, `flags`, `audit_logs`.

---

## 4. Deploy Edge Functions

Edge Functions require the [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started). Install it first, then log in and link your project:

```bash
# Install (macOS/Linux via Homebrew, or download from releases page)
brew install supabase/tap/supabase

# Log in
supabase login

# Link to your project (run from the repo root)
supabase link --project-ref <your-project-ref>
# The project ref is the subdomain part of your URL: xyzabcdef
```

Deploy all 7 functions:

```bash
supabase functions deploy create-profile
supabase functions deploy compute-matches
supabase functions deploy approve-claim
supabase functions deploy reject-claim
supabase functions deploy dispute-claim
supabase functions deploy resolve-dispute
supabase functions deploy moderate-action
```

Each function reads `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` from the Deno runtime environment, which Supabase injects automatically — you do not need to set those manually.

> **Windows note:** The Supabase CLI works on Windows via WSL2. Run the commands above inside a WSL2 terminal, not PowerShell.

---

## 5. Set Up the Auth Webhook

The `create-profile` Edge Function must fire automatically when a new user registers so a `profiles` row is created with the service role (bypassing RLS).

1. In Supabase Dashboard → **Authentication → Hooks**.
2. Click **Add hook**.
3. Set:
   - **Event:** `user.created`
   - **Hook type:** Supabase Edge Functions
   - **Function:** `create-profile`
4. Click **Save**.

Test it by registering a new account in the app. After confirming the email, a row should appear in the `profiles` table with the same `id` as the auth user.

---

## 6. Create and Configure Storage Buckets

Three storage buckets are required. Create each one in **Supabase Dashboard → Storage → New bucket**.

### `avatars` — Public

| Setting | Value |
|---|---|
| Name | `avatars` |
| Public bucket | ✅ Yes |
| File size limit | 2 MB |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp` |

### `report-images` — Public

| Setting | Value |
|---|---|
| Name | `report-images` |
| Public bucket | ✅ Yes |
| File size limit | 5 MB |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp` |

### `claim-evidence` — Private

| Setting | Value |
|---|---|
| Name | `claim-evidence` |
| Public bucket | ❌ No |
| File size limit | 5 MB |
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp` |

After creating the buckets, the RLS storage policies defined in the migrations handle access control automatically:
- `avatars`: public read; owner manages their own folder (`{user_id}/...`)
- `report-images`: public read; reporter uploads/deletes in their report folder (`{report_id}/...`)
- `claim-evidence`: private; only the claimant and the report's reporter can read; claimant uploads to their claim folder (`{claim_id}/...`)

Evidence images are never served via a plain URL. The Flutter app downloads them using `supabase.storage.from('claim-evidence').download(path)`, which attaches the user's JWT as a Bearer token and enforces the RLS policy server-side.

---

## 7. First-Run Checklist

Before running the app, confirm all of the following:

- [ ] `.env` contains valid `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- [ ] `flutter pub run build_runner build --delete-conflicting-outputs` ran successfully after editing `.env`
- [ ] All 8 SQL migrations ran without errors in SQL Editor
- [ ] All 7 Edge Functions deployed successfully (`supabase functions deploy` returned no errors)
- [ ] Auth webhook `user.created → create-profile` is saved and active
- [ ] Three storage buckets created: `avatars` (public), `report-images` (public), `claim-evidence` (private)
- [ ] `flutter analyze` returns zero errors
- [ ] `flutter test` returns all passing

Run the app:

```bash
flutter run
```

Register a new account, confirm the email, and verify a row appears in the `profiles` table.

---

## 8. Troubleshooting

### "Invalid API key" or blank screen on launch

The Supabase URL or anon key in `.env` is wrong, or `build_runner` was not re-run after editing `.env`. Check the value in **Project Settings → API**, update `.env`, and run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Profile not created after registration

The `create-profile` Auth webhook is not configured or the Edge Function failed to deploy. Check:
1. **Authentication → Hooks** — confirm the hook exists and is active.
2. **Edge Functions → create-profile → Logs** — look for runtime errors.
3. Redeploy: `supabase functions deploy create-profile`

### "new row violates row-level security policy"

A migration did not run, or ran in the wrong order. Check the **Table Editor** and confirm all 7 tables exist. If `profiles` is missing, run migration 2 first.

The most common ordering mistake is running migration 6 (claims) before migration 3 (item_reports) — `claims` has a foreign key to `item_reports`.

### Images not loading for claim evidence

Evidence images require an authenticated session. If a user is not logged in, the download call will return a 400/403. Ensure the user is authenticated before navigating to a claim detail screen.

If images fail even when authenticated, check that:
1. The `claim-evidence` bucket is set to **Private**.
2. The storage RLS policies from migration 6 were applied (check **Storage → Policies**).

### `flutter analyze` reports errors after a clean clone

Run code generation first — Freezed, Riverpod, and Envied all produce `.g.dart` / `.freezed.dart` files that are not committed:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Edge Function deployment fails on Windows

The Supabase CLI requires WSL2 on Windows. Open a WSL2 terminal and run `supabase functions deploy` from there. The repo directory is accessible at `/mnt/c/Users/<you>/...`.
