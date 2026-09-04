import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
export function PermissionExplainer(){
  const perms = [
    {name:'Location (Fine)', why:'Live tracking & last known location', when:'Requested before tracking starts', fallback:'Shows Last known + accuracy ±m, offline queue if denied'},
    {name:'Background Location', why:'Recovery when app not active', when:'Explained, then requested only if user enables Lost Mode', fallback:'Activity event LOCATION UNAVAILABLE, owner warned'},
    {name:'Camera', why:'Recovery evidence (front/rear)', when:'Only after Lost Mode + explicit consent', fallback:'Evidence shows UNSUPPORTED, respects OS privacy indicator'},
    {name:'Notifications', why:'Critical recovery events', when:'At onboarding, with rationale', fallback:'In-app activity still works, push shows UNSUPPORTED'},
    {name:'Bluetooth/Nearby', why:'Nearby recovery where supported', when:'Optional, with finder consent', fallback:'Uses Wi-Fi + QR + offline queue'},
  ];
  return (
    <Card>
      <CardHeader><CardTitle>Permissions — explained before request (PRD 9)</CardTitle></CardHeader>
      <CardContent className="space-y-3">
        {perms.map(p=>(
          <div key={p.name} className="rounded-lg border p-3">
            <p className="text-sm font-medium">{p.name}</p>
            <p className="text-xs text-muted-foreground mt-1"><span className="font-medium">Why:</span> {p.why}</p>
            <p className="text-xs text-muted-foreground"><span className="font-medium">When:</span> {p.when}</p>
            <p className="text-xs text-muted-foreground"><span className="font-medium">If denied:</span> {p.fallback}</p>
          </div>
        ))}
        <p className="text-xs text-muted-foreground">Never bypass permission, never bypass OS privacy indicator, never access camera without authorization (PRD 42).</p>
      </CardContent>
    </Card>
  );
}
