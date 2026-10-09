# FindBack — Requirements Specification
**Version:** 1.1  
**Phase:** 1 — Blueprint  
**Status:** Decisions Locked

---

## 1. Purpose and Scope

FindBack is a mobile application (Flutter/Android primary, iOS secondary) that allows users to report lost or found items, search for matches, submit ownership claims with private evidence, and have those claims reviewed by the item reporter and/or a moderator. The system is designed to resist fraudulent claims, prevent evidence leakage, and provide a transparent audit trail.

---

## 2. Actors

| Actor | Description |
|---|---|
| **Guest** | Unauthenticated visitor. Can browse public reports and search. Cannot report, claim, or message. |
| **Authenticated User** | Registered user. Can report items, search, claim, upload evidence, receive notifications. |
| **Reporter** | The user who created a specific item report. Has special privileges on that report (approve/reject claims, mark resolved). |
| **Claimant** | A user who has submitted a claim on a report they did not create. |
| **Moderator** | Platform-trusted user. Can review flagged content, escalate disputes, mark items resolved, suspend users. |
| **Admin** | Supabase-side role only (never a client-set flag). Full read access for auditing. |

---

## 3. Functional Requirements

### 3.1 User Registration and Authentication

**FR-AUTH-01** — Email/password registration with email verification.  
**FR-AUTH-02** — Sign-in with email and password.  
**FR-AUTH-03** — Password reset via emailed magic link.  
**FR-AUTH-04** — Persistent session across app restarts (Supabase session refresh).  
**FR-AUTH-05** — Sign-out clears local session and navigates to the login screen.  
**FR-AUTH-06** — Unverified users may not post reports or claims (403 on server, gated in UI).  
**FR-AUTH-07** — (Optional, Phase 7) OAuth login via Google.

**Acceptance Criteria:**
- A new user can register, receive a verification email, verify their account, and sign in within a single app session.
- A user who attempts to post a report without a verified email receives a clear error message and is not allowed to proceed.
- Session persists after the app is killed and relaunched.
- Signing out immediately invalidates the local session and redirects to auth screens.

---

### 3.2 User Profiles

**FR-PROF-01** — A profile row is created automatically on first sign-in (via Supabase trigger or Edge Function).  
**FR-PROF-02** — Profile fields: `display_name` (required), `avatar_url` (optional), `bio` (optional, ≤ 280 chars), `location_text` (optional, free-text city/region), `is_moderator` (server-set only), `is_banned` (server-set only), `created_at`, `updated_at`.  
**FR-PROF-03** — Users can edit their own `display_name`, `avatar_url`, `bio`, and `location_text`.  
**FR-PROF-04** — Avatar images are uploaded to Supabase Storage (`avatars/` bucket) and limited to 2 MB, JPEG/PNG/WEBP.  
**FR-PROF-05** — Public profile page shows display name, avatar, bio, and the user's public item reports.  
**FR-PROF-06** — `is_moderator` and `is_banned` can only be set by a Postgres function called by a service-role Edge Function — never by a client RLS update.

**Acceptance Criteria:**
- Profile is auto-created on first sign-in; the user is prompted to complete their display name if blank.
- Editing profile fields and uploading an avatar saves successfully and reflects immediately in the UI.
- A user cannot set `is_moderator = true` via any client API call.

---

### 3.3 Lost/Found Reports

**FR-RPT-01** — Two report types: `LOST` and `FOUND`.  
**FR-RPT-02** — Required fields: `type`, `title` (≤ 100 chars), `description` (≤ 2000 chars), `category` (enum), `date_of_incident` (date, not future), `location_text` (free-text, ≤ 200 chars).  
**FR-RPT-03** — Optional fields: `latitude`, `longitude` (reserved in schema for future map feature — **not collected by the Flutter UI in MVP**), `reward_offered` (boolean), `reward_description` (≤ 200 chars, required if reward = true).  
**FR-RPT-04** — Up to 5 images per report. Each ≤ 5 MB. Formats: JPEG, PNG, WEBP.  
**FR-RPT-05** — Report statuses: `ACTIVE` → `CLAIMED` → `RESOLVED` | `CLOSED`. Reporter can manually close; system moves to `CLAIMED` when a claim is approved; reporter marks `RESOLVED` when item is returned.  
**FR-RPT-06** — Reporter can edit their own report while it is `ACTIVE`.  
**FR-RPT-07** — Reporter can delete their report while it is `ACTIVE` (soft-delete; images remain in storage for 30 days per moderation policy).  
**FR-RPT-08** — A report is visible to all users (including guests) when `ACTIVE` or `RESOLVED`. `CLOSED` reports are visible to the reporter only.  
**FR-RPT-09** — Item categories (fixed enum): `ELECTRONICS`, `DOCUMENTS_KEYS`, `BAGS_LUGGAGE`, `CLOTHING_ACCESSORIES`, `PETS`, `JEWELRY`, `SPORTS_EQUIPMENT`, `BOOKS_STATIONERY`, `TOYS`, `VEHICLES`, `MONEY_CARDS`, `OTHER`.

**Acceptance Criteria:**
- Submitting a report with all required fields creates a visible card in the feed and navigates to the report detail screen.
- Attempting to submit without required fields shows field-level validation errors.
- Images upload asynchronously; the report submits even if image upload is still in progress (images attach on completion).
- A reporter can edit title/description/images while the report is ACTIVE; the edit timestamp is recorded.
- Status transitions are enforced: a `RESOLVED` report cannot return to `ACTIVE`.

---

### 3.4 Image Uploads

**FR-IMG-01** — Report images stored in `report-images/` bucket (public read for active reports).  
**FR-IMG-02** — Evidence images stored in `claim-evidence/` bucket (private; only claimant and reporter can read their respective claim's evidence).  
**FR-IMG-03** — Avatar images stored in `avatars/` bucket (public read).  
**FR-IMG-04** — All uploads go through Flutter; no pre-signed URL delegation to the client for arbitrary paths.  
**FR-IMG-05** — Image filenames are server-generated UUIDs; user-supplied filenames are not used.  
**FR-IMG-06** — A moderator can delete any image from storage via an Edge Function (not direct storage RLS override).

**Acceptance Criteria:**
- Uploading an image from the gallery/camera attaches it to the report with a progress indicator.
- A user cannot access another user's claim-evidence images by guessing the URL.
- Images are displayed with cached network image; broken images show a placeholder.

---

### 3.5 Search and Filters

**FR-SRCH-01** — Full-text search across `title` and `description` using PostgreSQL `tsvector` (GIN index).  
**FR-SRCH-02** — Filters: `type` (LOST/FOUND/both), `category`, `date_range` (from/to), `location_text` (partial match), `status` (default: ACTIVE only).  
**FR-SRCH-03** — Results sorted by relevance (when search query present) or `created_at DESC` (browse mode).  
**FR-SRCH-04** — Pagination via cursor (keyset) — no offset pagination.  
**FR-SRCH-05** — Search is available to guests.

**Acceptance Criteria:**
- Searching "red backpack" returns reports containing those words in title or description, ranked by relevance.
- Filtering by category and date range narrows results correctly.
- Pagination loads the next page without duplicating or skipping items.

---

### 3.6 Item Matching

**FR-MATCH-01** — When a new report is submitted, a background match job computes similarity scores against reports of the opposite type (LOST matches against FOUND and vice versa).  
**FR-MATCH-02** — Match score is a weighted combination of: category match (40%), text similarity via `pg_trgm` (40%), date proximity within 14 days (10%), location text similarity (10%).  
**FR-MATCH-03** — Matches with score ≥ 0.45 are stored in `item_matches` and surfaced to the reporter as "Possible Matches."  
**FR-MATCH-04** — A match score is never treated as proof of ownership; it is only a suggestion.  
**FR-MATCH-05** — The reporter can dismiss a suggested match (stored as `dismissed`).  
**FR-MATCH-06** — Match computation runs in a Supabase Edge Function triggered by a database webhook on `item_reports` INSERT.  
**FR-MATCH-07** — Match scores are recomputed when a report's title, description, category, or date changes.

**Acceptance Criteria:**
- Submitting a FOUND report for "black iPhone 14" when a LOST report exists for "iPhone 14 black case" produces a match with score ≥ 0.45.
- The match appears on the LOST reporter's detail screen under "Possible Matches."
- The reporter can dismiss the match and it disappears from the suggestions list.
- A dismissed match does not reappear after the report is edited.

---

### 3.7 Ownership Claims

**FR-CLAIM-01** — Any authenticated, verified user (except the reporter) may submit a claim on an `ACTIVE` report.  
**FR-CLAIM-02** — A user may have at most one active claim per report (enforced by unique partial index, not just UI).  
**FR-CLAIM-03** — Claim fields: `description` (≤ 1000 chars, required), `evidence_images` (1–5 images, stored in `claim-evidence/` bucket), `contact_preference` (enum: `IN_APP` | `EMAIL` | `PHONE`), `contact_detail` (required if EMAIL or PHONE).  
**FR-CLAIM-04** — Claim statuses: `PENDING` → `APPROVED` | `REJECTED` | `WITHDRAWN` | `DISPUTED`.  
**FR-CLAIM-05** — Only the reporter may approve or reject a claim on their own report — never a client-side field update.  
**FR-CLAIM-06** — Approving a claim moves the report to `CLAIMED` status and sets all other `PENDING` claims to `REJECTED` automatically (database trigger or Edge Function).  
**FR-CLAIM-07** — A claimant may withdraw their own `PENDING` claim.  
**FR-CLAIM-08** — A claimant may dispute a `REJECTED` claim once; this sets status to `DISPUTED` and notifies the moderator.  
**FR-CLAIM-09** — After a dispute, only a moderator may resolve it (`APPROVED` or `REJECTED`).  
**FR-CLAIM-10** — The reporter can see all claims on their report. The claimant can only see their own claim details. Other users cannot see any claims on a report.  
**FR-CLAIM-11** — Evidence images are private to the claimant and the reporter of the specific report.

**Acceptance Criteria:**
- A user cannot submit two active claims on the same report (second attempt returns a clear error).
- The reporter sees a list of pending claims with claimant display name, description, and a button to view evidence.
- Approving a claim automatically rejects all others and moves the report to CLAIMED status.
- A claimant cannot view another user's evidence images (confirmed by attempting direct URL access).
- Status transitions are server-validated and cannot be bypassed by a direct API call from the client.

---

### 3.8 Notifications

**FR-NOTIF-01** — In-app notification feed showing all events for the authenticated user.  
**FR-NOTIF-02** — Notification triggers:
  - New claim on your report
  - Your claim was approved
  - Your claim was rejected
  - A possible match found for your report
  - Your dispute was resolved
  - A moderator action was taken on your report or claim
  - (Phase 7) New in-app message  
**FR-NOTIF-03** — Notifications are stored in the `notifications` table, linked to the user.  
**FR-NOTIF-04** — Notifications have `read` / `unread` state; bulk "mark all read" action supported.  
**FR-NOTIF-05** — Push notifications (FCM) are out of scope for Phase 1–4; added in Phase 7.  
**FR-NOTIF-06** — Notification count badge on nav icon shows unread count.

**Acceptance Criteria:**
- When a claim is submitted on a report, the reporter receives an in-app notification within the same session.
- Marking a notification as read updates the badge count immediately.
- A user cannot read another user's notifications.

---

### 3.9 Admin Moderation

**FR-MOD-01** — Any user can flag a report or claim as inappropriate.  
**FR-MOD-02** — Moderators see a moderation queue of flagged items.  
**FR-MOD-03** — Moderator actions: remove report (soft-delete), remove claim, warn user, ban user, resolve disputed claim.  
**FR-MOD-04** — All moderator actions are written to `audit_logs` with `actor_id`, `action`, `target_type`, `target_id`, `reason`, and `created_at`.  
**FR-MOD-05** — `is_moderator` is set only via a privileged Edge Function with service-role key — never by a client call.  
**FR-MOD-06** — Banned users receive a "Your account has been suspended" message on sign-in and cannot post reports or claims.

**Acceptance Criteria:**
- A moderator can see the flagged items queue and take action on each.
- Banning a user prevents them from creating reports or claims (enforced by RLS, not just UI check).
- Every moderator action appears in `audit_logs` with full detail.
- A non-moderator cannot access the moderation queue screen (route guard + RLS).

---

## 4. Non-Functional Requirements

**NFR-PERF-01** — Initial feed load (first 20 items) completes in ≤ 2 seconds on a 4G connection.  
**NFR-PERF-02** — Image upload for a 5 MB file completes in ≤ 10 seconds on a 4G connection.  
**NFR-PERF-03** — Full-text search returns results in ≤ 1.5 seconds.  
**NFR-SEC-01** — RLS is enabled on every client-accessible table. Service-role key never ships in the Flutter app.  
**NFR-SEC-02** — All sensitive status transitions (claim approval, report resolution, ban) are server-validated.  
**NFR-SEC-03** — Evidence images are never accessible via a guessable public URL.  
**NFR-SCALE-01** — Schema supports up to 500,000 reports and 2,000,000 claims without structural changes.  
**NFR-ACCESS-01** — Color contrast ratio ≥ 4.5:1 (WCAG AA). All interactive elements have semantic labels.  
**NFR-OFFLINE-01** — App shows cached feed data when offline; displays a clear "offline" banner.

---

## 5. Out of Scope (Phase 1)

- Real-time push notifications (FCM) — Phase 7
- OAuth social login — Phase 7
- In-app messaging — Phase 7
- Map view with pin clustering — Phase 5+
- Multi-language / i18n — post-MVP
- Web or desktop targets
- Payment processing for rewards
