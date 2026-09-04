-- RLS policies - supabase friendly, IF NOT EXISTS handling via DO
DO $$ BEGIN
  ALTER TABLE users ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE profiles ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE devices ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE device_credentials ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE device_permissions ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE device_locations ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE location_sessions ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE location_sources ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE location_history ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE lost_cases ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE lost_commands ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE command_results ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE activity_events ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE recovery_events ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE finder_sessions ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE qr_tokens ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE rescue_sessions ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE trusted_contacts ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE trusted_permissions ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE evidence ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE evidence_uploads ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE notifications ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE admin_actions ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;
DO $$ BEGIN ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY; EXCEPTION WHEN others THEN null; END $$;

CREATE OR REPLACE FUNCTION current_user_id() RETURNS UUID AS $$ SELECT auth.uid(); $$ LANGUAGE sql STABLE SECURITY DEFINER;
CREATE OR REPLACE FUNCTION user_is_admin() RETURNS BOOLEAN AS $$ SELECT EXISTS (SELECT 1 FROM admin_users WHERE user_id=auth.uid()); $$ LANGUAGE sql STABLE SECURITY DEFINER;

DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (id=current_user_id());
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (id=current_user_id());
DROP POLICY IF EXISTS "Owners can view their devices" ON devices;
CREATE POLICY "Owners can view their devices" ON devices FOR SELECT USING (user_id=current_user_id());
DROP POLICY IF EXISTS "Owners can insert their devices" ON devices;
CREATE POLICY "Owners can insert their devices" ON devices FOR INSERT WITH CHECK (user_id=current_user_id());
DROP POLICY IF EXISTS "Owners can update their devices" ON devices;
CREATE POLICY "Owners can update their devices" ON devices FOR UPDATE USING (user_id=current_user_id());
DROP POLICY IF EXISTS "Owners can view device locations" ON device_locations;
CREATE POLICY "Owners can view device locations" ON device_locations FOR SELECT USING (EXISTS (SELECT 1 FROM devices WHERE id=device_locations.device_id AND user_id=current_user_id()));
DROP POLICY IF EXISTS "Anyone can view location sources" ON location_sources;
CREATE POLICY "Anyone can view location sources" ON location_sources FOR SELECT USING (is_active=TRUE);
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (user_id=current_user_id());

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
