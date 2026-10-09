CREATE TABLE notifications (
  id          uuid              PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid              NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type        notification_type NOT NULL,
  title       text              NOT NULL,
  body        text              NOT NULL,
  payload     jsonb             NOT NULL DEFAULT '{}',
  is_read     boolean           NOT NULL DEFAULT false,
  created_at  timestamptz       NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user_unread ON notifications (user_id, created_at DESC) WHERE is_read = false;
CREATE INDEX idx_notifications_user_all ON notifications (user_id, created_at DESC);
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications FORCE ROW LEVEL SECURITY;
CREATE POLICY "notifications_select" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notifications_no_insert" ON notifications FOR INSERT WITH CHECK (false);
CREATE POLICY "notifications_mark_read" ON notifications FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid() AND is_read = true);
