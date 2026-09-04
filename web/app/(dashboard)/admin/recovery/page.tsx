import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
export default function AdminRecoveryPage(){
  return (
    <AppShell>
      <div className="space-y-4">
        <h1 className="text-xl font-bold">Admin — Recovery Center</h1>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            {k:'Active Cases', v:'—'},
            {k:'Online Lost', v:'—'},
            {k:'Offline Lost', v:'—'},
            {k:'Finder Sightings', v:'—'},
          ].map(c=>(
            <Card key={c.k}><CardContent className="p-4"><p className="text-xs text-muted-foreground">{c.k}</p><p className="text-xl font-bold">{c.v}</p></CardContent></Card>
          ))}
        </div>
        <Card><CardHeader><CardTitle>Live Map — active recovery cases <Badge variant="outline">Realtime</Badge></CardTitle></CardHeader>
          <CardContent><p className="text-sm text-muted-foreground">Map shows active cases with accuracy, confidence, source (PRD 72).</p><div className="h-64 rounded-xl bg-muted mt-3 flex items-center justify-center text-sm text-muted-foreground">Live Map placeholder — provider-agnostic (Leaflet)</div></CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
