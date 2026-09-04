import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import Link from 'next/link';

export default function DashboardPage(){
  return (
    <AppShell>
      <div className="space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">Overview</h1>
            <p className="text-sm text-muted-foreground">Recovery-first control center. Honest status, not fake realtime.</p>
          </div>
          <div className="flex gap-2">
            <Link href="/devices" className="btn-primary btn-sm">Add Device</Link>
            <Link href="/map" className="btn-secondary btn-sm">Live Map</Link>
          </div>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { label:'Devices', value:'—', sub:'Register your first device' },
            { label:'Online', value:'—', sub:'Realtime via Supabase' },
            { label:'Lost cases', value:'0', sub:'No active cases' },
            { label:'Finder sightings', value:'0', sub:'No sightings yet' },
          ].map(s=>(
            <Card key={s.label}><CardContent className="p-4"><p className="text-xs text-muted-foreground">{s.label}</p><p className="text-2xl font-bold mt-1">{s.value}</p><p className="text-xs text-muted-foreground mt-1">{s.sub}</p></CardContent></Card>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <Card className="lg:col-span-2">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">Recovery State <Badge variant="outline">NORMAL</Badge></CardTitle>
              <CardDescription>Lost lifecycle: NORMAL → LOST → SEARCHING → SIGHTED → RECOVERING → RECOVERED</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="rounded-lg border bg-muted/30 p-4">
                <p className="text-sm font-medium">No device is in Lost Mode</p>
                <p className="text-xs text-muted-foreground mt-1">When you mark a device as lost, emergency actions (LOCATE, RING, LOCK, QR) become primary — not buried in menus.</p>
              </div>
              <div className="flex gap-2">
                <Link href="/devices" className="btn-primary btn-sm">Go to Devices</Link>
                <Link href="/activity" className="btn-secondary btn-sm">View Activity</Link>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader><CardTitle>Offline Awareness</CardTitle><CardDescription>Offline is a first-class state</CardDescription></CardHeader>
            <CardContent className="space-y-2 text-sm">
              <p className="text-muted-foreground">GPS → Local encrypted queue → Internet returns → Sync → Realtime</p>
              <div className="rounded-lg border p-3 bg-surface">
                <p className="font-medium">Sync engine</p>
                <p className="text-xs text-muted-foreground">Idempotent, retry-safe, resumable, ordered, deduped. Every event has a UUID.</p>
              </div>
              <p className="text-xs text-muted-foreground">If device loses connectivity: last known location, battery, and offline history are preserved.</p>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader><CardTitle>Platform Honesty</CardTitle><CardDescription>We never fake capabilities</CardDescription></CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
            <div className="rounded-lg border p-3"><p className="font-medium">Lock / Ring / Vibrate</p><p className="text-xs text-muted-foreground mt-1">Uses official OS APIs. Shows UNSUPPORTED when not allowed. No fake lock.</p></div>
            <div className="rounded-lg border p-3"><p className="font-medium">Camera Evidence</p><p className="text-xs text-muted-foreground mt-1">Requires foreground permission. Respects OS privacy indicator. Offline queue encrypted.</p></div>
            <div className="rounded-lg border p-3"><p className="font-medium">Factory Reset</p><p className="text-xs text-muted-foreground mt-1">Account identity + crypto binding + server ownership. No claim of universal reset prevention.</p></div>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
