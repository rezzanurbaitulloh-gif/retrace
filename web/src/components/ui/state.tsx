import { ReactNode } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

type State = 'loading'|'loaded'|'empty'|'error'|'offline'|'partial'|'unauthorized'|'permissionDenied'|'syncing'|'success'|'failure'|'unsupported';

export function StateView({state, title, description, action, children}:{state:State; title?:string; description?:string; action?:ReactNode; children?:ReactNode}){
  const icons:Record<State,string> = {
    loading:'⏳', loaded:'✓', empty:'∅', error:'✕', offline:'📡', partial:'◐',
    unauthorized:'🔒', permissionDenied:'🚫', syncing:'🔄', success:'✓', failure:'✕', unsupported:'⚠️'
  };
  if (state==='loading') return <div className="rounded-xl border bg-muted/30 p-8 flex flex-col items-center gap-3"><div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" aria-hidden="true" /><p className="text-sm font-medium">Loading…</p><p className="text-xs text-muted-foreground">Fetching from Supabase + local cache</p></div>;
  if (state==='loaded' && children) return <>{children}</>;
  return (
    <Card>
      <CardContent className="p-8 text-center space-y-3">
        <div className="text-2xl" aria-hidden="true">{icons[state]}</div>
        <p className="font-medium">{title ?? state}</p>
        {description && <p className="text-sm text-muted-foreground max-w-md mx-auto">{description}</p>}
        {action && <div className="pt-2 flex justify-center">{action}</div>}
        {children}
        <p className="text-xs text-muted-foreground">State: {state.toUpperCase()} — offline queue, retry, sync handled where applicable</p>
      </CardContent>
    </Card>
  );
}
export function OfflineBanner(){ return <div className="rounded-lg border border-amber-200 bg-amber-50 dark:bg-amber-950/20 dark:border-amber-900 px-3 py-2 text-sm flex items-center gap-2"><span aria-hidden="true">📡</span> Offline — data queued locally and will sync when connection restores</div>; }
export function UnsupportedBanner({feature}:{feature:string}){ return <div className="rounded-lg border bg-muted px-3 py-2 text-sm"><span className="font-medium">UNSUPPORTED:</span> {feature} not allowed by OS. Last known location + finder QR still available.</div>; }
