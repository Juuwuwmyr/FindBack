-- FindBack: item_reports table
-- Migration: 20240003000000_item_reports

-- Required for tsvector generation and trigram search (TASK-020 will add pg_trgm)
CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;

CREATE TABLE item_reports (
  id                uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id       uuid         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type              report_type  NOT NULL,
  status            report_status NOT NULL DEFAULT 'ACTIVE',
  title             text         NOT NULL CHECK (char_length(title) BETWEEN 1 AND 100),
  description       text         NOT NULL CHECK (char_length(description) BETWEEN 1 AND 2000),
  category          item_category NOT NULL,
  date_of_incident  date         NOT NULL CHECK (date_of_incident <= CURRENT_DATE),
  location_text     text         NOT NULL CHECK (char_length(location_text) BETWEEN 1 AND 200),
  latitude          numeric(9,6),
  longitude         numeric(9,6),
  image_urls        text[]       NOT NULL DEFAULT '{}',
  reward_offered    boolean      NOT NULL DEFAULT false,
  reward_description text,
  search_vector     tsvector     GENERATED ALWAYS AS (
                      to_tsvector('english',
                        coalesce(title, '') || ' ' || coalesce(description, ''))
                    ) STORED,
  deleted_at        timestamptz,
  created_at        timestamptz  NOT NULL DEFAULT now(),
  updated_at        timestamptz
);

-- Auto-update updated_at
CREATE TRIGGER set_item_reports_updated_at
  BEFORE UPDATE ON item_reports
  FOR EACH ROW
  EXECUTE FUNCTION extensions.moddatetime(updated_at);

-- Full-text search index
CREATE INDEX idx_item_reports_search
  ON item_reports USING GIN (search_vector);

-- Feed query index: active reports sorted by date
CREATE INDEX idx_item_reports_status_created
  ON item_reports (status, created_at DESC)
  WHERE deleted_at IS NULL;

-- Category filter index
CREATE INDEX idx_item_reports_category
  ON item_reports (category)
  WHERE deleted_at IS NULL;

-- Reporter's own reports
CREATE INDEX idx_item_reports_reporter
  ON item_reports (reporter_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- Enable RLS
ALTER TABLE item_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_reports FORCE ROW LEVEL SECURITY;

-- Public read: non-deleted ACTIVE or RESOLVED reports; own CLOSED reports
CREATE POLICY "item_reports_select"
  ON item_reports FOR SELECT
  USING (
    deleted_at IS NULL
    AND (
      status IN ('ACTIVE', 'RESOLVED')
      OR reporter_id = auth.uid()
    )
  );

-- Authenticated, non-banned users can insert
CREATE POLICY "item_reports_insert"
  ON item_reports FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND reporter_id = auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_banned = true
    )
  );

-- Reporter can update own ACTIVE report; cannot change status directly
CREATE POLICY "item_reports_update_own"
  ON item_reports FOR UPDATE
  USING (reporter_id = auth.uid() AND status = 'ACTIVE' AND deleted_at IS NULL)
  WITH CHECK (
    reporter_id = auth.uid()
  );

-- Soft delete: reporter sets deleted_at
CREATE POLICY "item_reports_delete_own"
  ON item_reports FOR DELETE
  USING (reporter_id = auth.uid() AND status = 'ACTIVE' AND deleted_at IS NULL);
