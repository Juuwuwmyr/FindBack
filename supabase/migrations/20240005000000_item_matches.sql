-- FindBack: item_matches table
-- Migration: 20240005000000_item_matches

CREATE TABLE item_matches (
  id              uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  lost_report_id  uuid         NOT NULL REFERENCES item_reports(id) ON DELETE CASCADE,
  found_report_id uuid         NOT NULL REFERENCES item_reports(id) ON DELETE CASCADE,
  score           numeric(4,3) NOT NULL CHECK (score >= 0 AND score <= 1),
  status          match_status NOT NULL DEFAULT 'PENDING',
  created_at      timestamptz  NOT NULL DEFAULT now(),
  CONSTRAINT item_matches_unique_pair UNIQUE (lost_report_id, found_report_id)
);

CREATE INDEX idx_matches_lost  ON item_matches (lost_report_id);
CREATE INDEX idx_matches_found ON item_matches (found_report_id);

ALTER TABLE item_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_matches FORCE ROW LEVEL SECURITY;

-- Reporter of either report can read matches
CREATE POLICY "matches_select"
  ON item_matches FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM item_reports
      WHERE (id = lost_report_id OR id = found_report_id)
        AND reporter_id = auth.uid()
    )
  );

-- No client inserts (service role only via Edge Function)
CREATE POLICY "matches_no_insert"
  ON item_matches FOR INSERT
  WITH CHECK (false);

-- Reporter of either side can dismiss
CREATE POLICY "matches_dismiss"
  ON item_matches FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM item_reports
      WHERE (id = lost_report_id OR id = found_report_id)
        AND reporter_id = auth.uid()
    )
  )
  WITH CHECK (status = 'DISMISSED');
