import { cn } from '@/lib/utils';
import { batteryStatus } from '@/lib/utils';
export function BatteryIndicator({level, isCharging, showLabel=true}:{level:number|null|undefined; isCharging?:boolean|null; showLabel?:boolean}){
  const status = batteryStatus(level);
  const tone = status==='CRITICAL' ? 'text-destructive' : status==='LOW' ? 'text-amber-500' : status==='MEDIUM' ? 'text-sky-500' : 'text-emerald-500';
  const width = level==null ? 0 : Math.max(0, Math.min(100, level));
  const bucket = level==null ? 'UNKNOWN' : level>50 ? '>50%' : level>20 ? '20–50%' : level>10 ? '10–20%' : level>=0 ? '<10%' : '—';
  const label = status==='CRITICAL' ? 'CRITICAL' : status;
  return (
    <div className="flex items-center gap-2">
      <div className="h-6 w-10 rounded border-2 border-foreground/20 p-0.5 flex">
        <div className={cn('rounded-sm transition-all', tone)} style={{width: `${width}%`, backgroundColor: 'currentColor'}} />
      </div>
      <div className="text-xs">
        <p className={cn('font-medium', tone)}>{level==null ? '—' : `${Math.round(level)}%`} {isCharging ? '⚡' : ''} {showLabel && `• ${bucket} • ${label}`}</p>
        <p className="text-muted-foreground">Low battery → tracking profile adapts (PRD 46)</p>
      </div>
    </div>
  );
}
