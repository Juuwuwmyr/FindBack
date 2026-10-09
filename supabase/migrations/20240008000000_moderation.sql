CREATE TABLE flags (
  id          uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type text  NOT NULL CHECK (target_type IN ('report', 'claim')),
  target_id   uuid  NOT NULL,
  reason      text  NOT NULL CHECK (char_length(reason) BETWEEN 1 AND 500),
  resolved    boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_flags_unresolved ON flags (created_at DESC) WHERE resolved = false;
ALTER TABLE flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE flags FORCE ROW LEVEL SECURITY;
CREATE POLICY "flags_select" ON flags FOR SELECT USING (reporter_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_moderator = true));
CREATE POLICY "flags_insert" ON flags FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND reporter_id = auth.uid() AND NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_banned = true));
CREATE POLICY "flags_resolve" ON flags FOR UPDATE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_moderator = true));

CREATE TABLE audit_logs (
  id          uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    uuid  REFERENCES profiles(id),
  action      text  NOT NULL,
  target_type text  NOT NULL,
  target_id   uuid  NOT NULL,
  reason      text,
  metadata    jsonb NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_logs_created ON audit_logs (created_at DESC);
CREATE INDEX idx_audit_logs_target ON audit_logs (target_type, target_id);
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs FORCE ROW LEVEL SECURITY;
CREATE POLICY "audit_logs_select" ON audit_logs FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_moderator = true));
CREATE POLICY "audit_logs_no_insert" ON audit_logs FOR INSERT WITH CHECK (false);
CREATE POLICY "audit_logs_no_update" ON audit_logs FOR UPDATE USING (false);
CREATE POLICY "audit_logs_no_delete" ON audit_logs FOR DELETE USING (false);
