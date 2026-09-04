export type DeviceState='ACTIVE'|'ONLINE'|'OFFLINE'|'LOST'|'RECOVERING'|'RECOVERED'|'DISABLED'|'PENDING';
export type LostLifecycle='NORMAL'|'LOST'|'SEARCHING'|'SIGHTED'|'RECOVERING'|'RECOVERED';
export type LocationSource='GPS'|'NETWORK'|'CELLULAR'|'NEARBY'|'FINDER'|'UNKNOWN';
export type LocationConfidence='HIGH'|'MEDIUM'|'LOW';
export type ActivityCategory='SECURITY'|'LOCATION'|'DEVICE'|'RECOVERY'|'FINDER'|'RESCUE'|'EVIDENCE'|'SYSTEM'|'ADMIN';
export type ActivityPriority='CRITICAL'|'IMPORTANT'|'INFO'|'DEBUG';
export type TrustedPermissionLevel='ALWAYS_TRACK'|'EMERGENCY_ONLY'|'RECOVERY_ONLY'|'NO_ACCESS';
export type CommandType='LOCATE'|'RING'|'VIBRATE'|'LOCK'|'SHOW_LOST_SCREEN'|'CONTACT_OWNER'|'QR_RECOVERY'|'RESCUE'|'ACTIVITY'|'EVIDENCE';
export type CommandStatus='QUEUED'|'SENT'|'DELIVERED'|'EXECUTED'|'FAILED'|'EXPIRED'|'ACKNOWLEDGED';
export type SyncStatus='PENDING'|'SYNCING'|'SYNCED'|'FAILED'|'CONFLICT';
export interface Device { id:string; user_id:string|null; name:string; brand:string|null; model:string|null; os:string|null; os_version:string|null; imei_1:string|null; imei_2:string|null; serial_number:string|null; retrace_device_id:string; cryptographic_identity:string; state:DeviceState; lost_state:LostLifecycle; battery_level:number|null; battery_status:string|null; is_online:boolean|null; last_known_location_accuracy:number|null; last_known_location_timestamp:string|null; created_at:string; }
export interface DeviceLocation { id:string; device_id:string; latitude:number; longitude:number; accuracy:number|null; altitude:number|null; speed:number|null; heading:number|null; device_timestamp:string; server_timestamp:string; source:LocationSource; confidence:LocationConfidence; sync_status:SyncStatus; }
export interface LostCase { id:string; device_id:string; status:LostLifecycle; recovery_message:string|null; contact_info:Record<string,unknown>|null; created_at?:string; }
export interface ActivityEvent { id:string; device_id:string; category:ActivityCategory; priority:ActivityPriority; event_type:string; title:string; description:string|null; created_at:string; }
export interface TrustedContact { id:string; user_id:string; contact_user_id:string; permission_level:TrustedPermissionLevel; accepted_at:string|null; revoked_at:string|null; }
