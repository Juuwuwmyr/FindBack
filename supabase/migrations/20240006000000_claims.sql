-- FindBack: claims table
-- Migration: 20240006000000_claims

CREATE TABLE claims (
  id                  uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id           uuid         NOT NULL REFERENCES item_reports(id) ON DELETE CASCADE,
  claimant_id         uuid         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status              claim_status NOT NULL DEFAULT 'PENDING',
  description         text         NOT NULL CHECK (char_length(description) BETWEEN 1 AND 1000),
  evidence_image_paths text[]      NOT NULL DEFAULT '{}',
  contact_preference  contact_pref NOT NULL,
  contact_detail      text,
  reviewer_id         uuid         REFERENCES profiles(id),
  reviewed_at         timestamptz,
  created_at          timestamptz  NOT NULL DEFAULT now(),
  updated_at          timestamptz
);

-- Auto-update updated_at
CREATE TRIGGER set_claims_updated_at
  BEFORE UPDATE ON claims
  FOR EACH ROW
  EXECUTE FUNCTION extensions.moddatetime(updated_at);

-- Index for reporter looking up all claims on their reports
CREATE INDEX idx_claims_report_id ON claims (report_id);

-- Prevent duplicate active claims: one active claim per user per report
CREATE UNIQUE INDEX idx_claims_one_active_per_user
  ON claims (report_id, claimant_id)
  WHERE status NOT IN ('WITHDRAWN', 'REJECTED');

-- Enable RLS
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE claims FORCE ROW LEVEL SECURITY;

-- Reporter sees all claims on their reports; claimant sees their own
CREATE POLICY "claims_select"
  ON claims FOR SELECT
  USING (
    claimant_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM item_reports
      WHERE id = report_id AND reporter_id = auth.uid()
    )
  );

-- Authenticated non-banned non-reporter can insert their own claim
CREATE POLICY "claims_insert"
  ON claims FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND claimant_id = auth.uid()
    AND NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_banned = true)
    AND NOT EXISTS (SELECT 1 FROM item_reports WHERE id = report_id AND reporter_id = auth.uid())
  );

-- Claimant can only withdraw their own PENDING claim (status->WITHDRAWN)
-- All other status transitions go through Edge Functions with service role
CREATE POLICY "claims_update_withdraw"
  ON claims FOR UPDATE
  USING (claimant_id = auth.uid() AND status = 'PENDING')
  WITH CHECK (status = 'WITHDRAWN');
