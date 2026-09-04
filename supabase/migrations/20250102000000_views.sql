create or replace view finder_sightings_view as select fs.id, fs.lost_case_id, fs.finder_location_accuracy, ST_Y(fs.finder_location) as latitude, ST_X(fs.finder_location) as longitude, fs.contact_info_shared, fs.sighting_reported, fs.reported_at, fs.created_at, fs.expires_at from finder_sessions fs where fs.finder_location is not null;
alter view finder_sightings_view set (security_invoker=true);
create or replace view device_latest_location_view as select distinct on (device_id) device_id, latitude, longitude, accuracy, altitude, speed, heading, source, confidence, device_timestamp, server_timestamp from device_locations order by device_id, device_timestamp desc;
alter view device_latest_location_view set (security_invoker=true);
grant select on finder_sightings_view to authenticated;
grant select on device_latest_location_view to authenticated;
