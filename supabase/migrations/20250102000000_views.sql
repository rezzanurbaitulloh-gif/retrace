-- Views with security_invoker
CREATE OR REPLACE VIEW device_latest_location_view AS
  SELECT DISTINCT ON (device_id) device_id, latitude, longitude, accuracy, altitude, speed, heading, source, confidence, device_timestamp, server_timestamp
  FROM device_locations ORDER BY device_id, device_timestamp DESC;
ALTER VIEW device_latest_location_view SET (security_invoker=true);
GRANT SELECT ON device_latest_location_view TO authenticated;
GRANT SELECT ON device_latest_location_view TO service_role;
