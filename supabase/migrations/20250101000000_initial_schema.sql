-- RETRACE Database Schema - Supabase compatible
CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA public;
-- Use gen_random_uuid() from pgcrypto (Supabase default)

DO $$ BEGIN
  CREATE TYPE device_state AS ENUM ('ACTIVE','ONLINE','OFFLINE','LOST','RECOVERING','RECOVERED','DISABLED','PENDING');
EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN
  CREATE TYPE lost_lifecycle AS ENUM ('NORMAL','LOST','SEARCHING','SIGHTED','RECOVERING','RECOVERED');
EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN
  CREATE TYPE location_source AS ENUM ('GPS','NETWORK','CELLULAR','NEARBY','FINDER','UNKNOWN');
EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN
  CREATE TYPE location_confidence AS ENUM ('HIGH','MEDIUM','LOW');
EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN
  CREATE TYPE activity_category AS ENUM ('SECURITY','LOCATION','DEVICE','RECOVERY','FINDER','RESCUE','EVIDENCE','SYSTEM','ADMIN');
EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN
  CREATE TYPE activity_priority AS ENUM ('CRITICAL','IMPORTANT','INFO','DEBUG');
EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN
  CREATE TYPE trusted_permission_level AS ENUM ('ALWAYS_TRACK','EMERGENCY_ONLY','RECOVERY_ONLY','NO_ACCESS');
EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN
  CREATE TYPE command_type AS ENUM ('LOCATE','RING','VIBRATE','LOCK','SHOW_LOST_SCREEN','CONTACT_OWNER','QR_RECOVERY','RESCUE','ACTIVITY','EVIDENCE');
EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN
  CREATE TYPE command_status AS ENUM ('QUEUED','SENT','DELIVERED','EXECUTED','FAILED','EXPIRED','ACKNOWLEDGED');
EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN
  CREATE TYPE sync_status AS ENUM ('PENDING','SYNCING','SYNCED','FAILED','CONFLICT');
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  phone_number TEXT UNIQUE,
  full_name TEXT NOT NULL,
  display_name TEXT,
  profile_photo_url TEXT,
  recovery_contacts JSONB DEFAULT '[]'::jsonb,
  address TEXT,
  notes TEXT,
  preferred_contact_method TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  email_verified BOOLEAN DEFAULT FALSE,
  phone_verified BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  recovery_pin_hash TEXT NOT NULL,
  recovery_secret_hash TEXT NOT NULL,
  recovery_email TEXT,
  recovery_phone TEXT,
  backup_codes JSONB DEFAULT '[]'::jsonb,
  security_settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  os TEXT,
  os_version TEXT,
  imei_1 TEXT,
  imei_2 TEXT,
  serial_number TEXT,
  phone_number TEXT,
  device_photo_url TEXT,
  purchase_date DATE,
  purchase_store TEXT,
  notes TEXT,
  retrace_device_id TEXT UNIQUE NOT NULL,
  cryptographic_identity TEXT NOT NULL,
  state device_state DEFAULT 'PENDING',
  lost_state lost_lifecycle DEFAULT 'NORMAL',
  last_known_location JSONB,
  last_known_location_accuracy DECIMAL(10,2),
  last_known_location_timestamp TIMESTAMPTZ,
  battery_level DECIMAL(5,2),
  battery_status TEXT,
  is_charging BOOLEAN,
  connection_type TEXT,
  is_online BOOLEAN DEFAULT FALSE,
  last_online_at TIMESTAMPTZ,
  last_offline_at TIMESTAMPTZ,
  offline_reason TEXT,
  permissions JSONB DEFAULT '{}'::jsonb,
  settings JSONB DEFAULT '{}'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  registered_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS device_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE UNIQUE,
  encryption_key_hash TEXT NOT NULL,
  auth_token_hash TEXT,
  push_token TEXT,
  apns_token TEXT,
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS device_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  permission_type TEXT NOT NULL,
  is_granted BOOLEAN DEFAULT FALSE,
  granted_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  OS_level BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(device_id, permission_type)
);

CREATE TABLE IF NOT EXISTS device_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  accuracy DECIMAL(10, 2),
  altitude DECIMAL(10, 2),
  speed DECIMAL(10, 2),
  heading DECIMAL(10, 2),
  device_timestamp TIMESTAMPTZ NOT NULL,
  server_timestamp TIMESTAMPTZ DEFAULT NOW(),
  source location_source DEFAULT 'UNKNOWN',
  confidence location_confidence DEFAULT 'LOW',
  sync_status sync_status DEFAULT 'PENDING',
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS location_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  tracking_profile TEXT,
  battery_at_start DECIMAL(5,2),
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS location_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  min_accuracy DECIMAL(10,2),
  max_accuracy DECIMAL(10,2),
  requires_internet BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS location_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  locations JSONB NOT NULL,
  total_distance DECIMAL(12,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(device_id, date)
);

CREATE TABLE IF NOT EXISTS lost_cases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  reported_by UUID REFERENCES users(id),
  reported_at TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at TIMESTAMPTZ,
  recovered_at TIMESTAMPTZ,
  status lost_lifecycle DEFAULT 'LOST',
  last_known_location JSONB,
  recovery_message TEXT,
  contact_info JSONB DEFAULT '{}'::jsonb,
  qr_token_id UUID,
  finder_sightings_count INTEGER DEFAULT 0,
  evidence_count INTEGER DEFAULT 0,
  rescue_attempts_count INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS lost_commands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lost_case_id UUID REFERENCES lost_cases(id) ON DELETE CASCADE,
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  command_type command_type NOT NULL,
  payload JSONB DEFAULT '{}'::jsonb,
  status command_status DEFAULT 'QUEUED',
  priority INTEGER DEFAULT 0,
  queued_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  executed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  error_message TEXT,
  result JSONB DEFAULT '{}'::jsonb,
  acknowledged_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS command_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  command_id UUID REFERENCES lost_commands(id) ON DELETE CASCADE,
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  success BOOLEAN NOT NULL,
  result_data JSONB DEFAULT '{}'::jsonb,
  error_code TEXT,
  error_message TEXT,
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  received_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS activity_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  lost_case_id UUID REFERENCES lost_cases(id) ON DELETE SET NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  category activity_category NOT NULL,
  priority activity_priority DEFAULT 'INFO',
  event_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  location JSONB,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS recovery_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lost_case_id UUID REFERENCES lost_cases(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  description TEXT,
  location JSONB,
  finder_id UUID,
  evidence_id UUID,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);



CREATE TABLE IF NOT EXISTS qr_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  lost_case_id UUID REFERENCES lost_cases(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  nonce TEXT NOT NULL,
  signed_payload JSONB NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  used_by_finder BOOLEAN DEFAULT FALSE,
  scan_count INTEGER DEFAULT 0,
  max_scans INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS finder_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lost_case_id UUID REFERENCES lost_cases(id) ON DELETE CASCADE,
  qr_token_id UUID REFERENCES qr_tokens(id) ON DELETE SET NULL,
  finder_location JSONB,
  finder_location_accuracy DECIMAL(10,2),
  contact_info_shared JSONB DEFAULT '{}'::jsonb,
  sighting_reported BOOLEAN DEFAULT FALSE,
  reported_at TIMESTAMPTZ,
  user_agent TEXT,
  ip_hash TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS rescue_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lost_case_id UUID REFERENCES lost_cases(id) ON DELETE CASCADE,
  finder_session_id UUID REFERENCES finder_sessions(id) ON DELETE SET NULL,
  tier INTEGER DEFAULT 3,
  status TEXT DEFAULT 'PENDING',
  connection_type TEXT,
  bandwidth_used BIGINT DEFAULT 0,
  data_transferred BIGINT DEFAULT 0,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  consent_given BOOLEAN DEFAULT FALSE,
  consent_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS trusted_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  contact_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  permission_level trusted_permission_level DEFAULT 'NO_ACCESS',
  invited_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  UNIQUE(user_id, contact_user_id)
);

CREATE TABLE IF NOT EXISTS trusted_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trusted_contact_id UUID REFERENCES trusted_contacts(id) ON DELETE CASCADE,
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  can_track BOOLEAN DEFAULT FALSE,
  can_view_location BOOLEAN DEFAULT FALSE,
  can_receive_alerts BOOLEAN DEFAULT FALSE,
  can_initiate_recovery BOOLEAN DEFAULT FALSE,
  emergency_only BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(trusted_contact_id, device_id)
);

CREATE TABLE IF NOT EXISTS evidence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  lost_case_id UUID REFERENCES lost_cases(id) ON DELETE SET NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  location JSONB,
  camera_source TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  file_hash TEXT NOT NULL,
  encryption_key_id TEXT,
  upload_status sync_status DEFAULT 'PENDING',
  uploaded_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  access_count INTEGER DEFAULT 0,
  last_accessed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS evidence_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  evidence_id UUID REFERENCES evidence(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  storage_bucket TEXT NOT NULL,
  file_size BIGINT,
  mime_type TEXT,
  checksum TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  verified BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
  lost_case_id UUID REFERENCES lost_cases(id) ON DELETE SET NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB DEFAULT '{}'::jsonb,
  priority activity_priority DEFAULT 'INFO',
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  role TEXT DEFAULT 'admin',
  permissions JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES admin_users(id)
);

CREATE TABLE IF NOT EXISTS admin_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES admin_users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  result JSONB DEFAULT '{}'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID NOT NULL,
  reason TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  result TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  ip_address INET,
  user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_retrace_device_id ON devices(retrace_device_id);
CREATE INDEX IF NOT EXISTS idx_devices_state ON devices(state);
CREATE INDEX IF NOT EXISTS idx_device_locations_device_id ON device_locations(device_id);
CREATE INDEX IF NOT EXISTS idx_device_locations_device_timestamp ON device_locations(device_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_lost_cases_device_id ON lost_cases(device_id);
CREATE INDEX IF NOT EXISTS idx_activity_events_device_id ON activity_events(device_id);
CREATE INDEX IF NOT EXISTS idx_qr_tokens_device_id ON qr_tokens(device_id);
CREATE INDEX IF NOT EXISTS idx_evidence_device_id ON evidence(device_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp DESC);

INSERT INTO location_sources (name, description, min_accuracy, max_accuracy, requires_internet) VALUES
  ('GPS','GPS/GNSS satellite positioning',3,50,FALSE),
  ('NETWORK','Wi-Fi positioning',10,200,TRUE),
  ('CELLULAR','Cell tower triangulation',100,2000,TRUE),
  ('NEARBY','Bluetooth/Nearby device signals',1,50,FALSE),
  ('FINDER','Finder reported sighting',5,100,TRUE),
  ('UNKNOWN','Unknown source',0,10000,FALSE)
ON CONFLICT (name) DO NOTHING;
