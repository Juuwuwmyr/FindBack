-- FindBack: Search infrastructure
-- Migration: 20240004000000_search

-- Enable trigram extension for similarity search and location matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Trigram index on location_text for partial location search
CREATE INDEX IF NOT EXISTS idx_item_reports_location
  ON item_reports USING GIN (location_text gin_trgm_ops);

-- Trigram index on title for fast similarity
CREATE INDEX IF NOT EXISTS idx_item_reports_title_trgm
  ON item_reports USING GIN (title gin_trgm_ops);

-- Full search function with filters and keyset pagination
CREATE OR REPLACE FUNCTION search_reports(
  p_query        text        DEFAULT NULL,
  p_type         report_type DEFAULT NULL,
  p_category     item_category DEFAULT NULL,
  p_date_from    date        DEFAULT NULL,
  p_date_to      date        DEFAULT NULL,
  p_location     text        DEFAULT NULL,
  p_cursor_created_at timestamptz DEFAULT NULL,
  p_cursor_id    uuid        DEFAULT NULL,
  p_limit        int         DEFAULT 20
)
RETURNS TABLE (
  id                uuid,
  reporter_id       uuid,
  type              report_type,
  status            report_status,
  title             text,
  description       text,
  category          item_category,
  date_of_incident  date,
  location_text     text,
  latitude          numeric,
  longitude         numeric,
  image_urls        text[],
  reward_offered    boolean,
  reward_description text,
  search_vector     tsvector,
  deleted_at        timestamptz,
  created_at        timestamptz,
  updated_at        timestamptz
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id, r.reporter_id, r.type, r.status, r.title, r.description,
    r.category, r.date_of_incident, r.location_text, r.latitude, r.longitude,
    r.image_urls, r.reward_offered, r.reward_description, r.search_vector,
    r.deleted_at, r.created_at, r.updated_at
  FROM item_reports r
  WHERE
    r.deleted_at IS NULL
    AND r.status IN ('ACTIVE', 'RESOLVED')
    AND (p_type IS NULL OR r.type = p_type)
    AND (p_category IS NULL OR r.category = p_category)
    AND (p_date_from IS NULL OR r.date_of_incident >= p_date_from)
    AND (p_date_to IS NULL OR r.date_of_incident <= p_date_to)
    AND (
      p_location IS NULL OR
      r.location_text ILIKE '%' || p_location || '%'
    )
    AND (
      p_query IS NULL OR p_query = '' OR
      r.search_vector @@ plainto_tsquery('english', p_query)
    )
    AND (
      p_cursor_created_at IS NULL OR p_cursor_id IS NULL OR
      r.created_at < p_cursor_created_at OR
      (r.created_at = p_cursor_created_at AND r.id < p_cursor_id)
    )
  ORDER BY
    CASE WHEN p_query IS NOT NULL AND p_query != ''
      THEN ts_rank(r.search_vector, plainto_tsquery('english', p_query))
      ELSE 0
    END DESC,
    r.created_at DESC,
    r.id DESC
  LIMIT p_limit;
END;
$$;
