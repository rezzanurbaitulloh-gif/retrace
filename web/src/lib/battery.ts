export function batteryBucket(level:number|null|undefined){
  if (level==null) return 'UNKNOWN';
  if (level>50) return '>50%';
  if (level>20) return '20–50%';
  if (level>10) return '10–20%';
  if (level>=0) return '<10%';
  return 'UNKNOWN';
}
export function trackingProfile({moving,lost,battery}:{moving:boolean; lost:boolean; battery:number|null|undefined}){
  if (lost && (battery??100)>20) return 'aggressive (10s)';
  if (lost) return 'conservative (30s)';
  if (moving) return 'moving (15s)';
  return 'stationary (60s)';
}
