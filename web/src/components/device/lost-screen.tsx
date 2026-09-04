import { Card, CardContent } from '@/components/ui/card';
export function LostScreenPreview({owner="Reja", recoveryId="RT-XXXX", contact="reja@example.com"}:{owner?:string; recoveryId?:string; contact?:string}){
  return (
    <Card className="max-w-sm mx-auto overflow-hidden border-2 border-destructive/20">
      <CardContent className="p-0">
        <div className="bg-destructive text-destructive-foreground p-4 text-center">
          <p className="font-bold tracking-widest text-sm">🔴 DEVICE LOST</p>
          <p className="text-xs mt-1 opacity-90">This device has been reported lost.</p>
        </div>
        <div className="p-4 space-y-3 text-center">
          <p className="text-sm">Owner: <span className="font-semibold">{owner}</span></p>
          <div className="grid grid-cols-2 gap-2">
            <a href={`tel:${contact}`} className="btn-primary btn-sm justify-center">CONTACT OWNER</a>
            <a href="#qr" className="btn-secondary btn-sm justify-center">SCAN TO HELP</a>
          </div>
          <p className="text-xs font-mono text-muted-foreground">Recovery ID: {recoveryId}</p>
          <div className="h-32 w-32 mx-auto rounded-lg border-2 border-dashed bg-muted flex items-center justify-center text-xs text-muted-foreground">QR</div>
          <p className="text-xs text-muted-foreground">Finder does not need account. QR is short-lived signed token, device-bound, nonce, replay-protected.</p>
        </div>
      </CardContent>
    </Card>
  );
}
