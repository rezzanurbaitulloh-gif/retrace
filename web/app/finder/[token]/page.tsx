'use client';
import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input, Label } from '@/components/ui/input';

export default function FinderPage({ params }:{params:{token:string}}){
  const token=params.token;
  const [locationGranted,setLocationGranted]=useState(false);
  const [coords,setCoords]=useState<{lat:number,lng:number}|null>(null);
  const [contact,setContact]=useState('');
  const [msg,setMsg]=useState<string|null>(null);
  const [loading,setLoading]=useState(false);

  async function requestLocation(){
    if (!navigator.geolocation){ setMsg('Geolocation not supported on this device.'); return; }
    navigator.geolocation.getCurrentPosition(pos=>{
      setCoords({ lat:pos.coords.latitude, lng:pos.coords.longitude });
      setLocationGranted(true);
      setMsg('Location captured. You can now send a sighting — owner will see it. Finder privacy: we do not share your identity unless you provide contact.');
    }, err=>{
      setMsg(`Location permission denied or unavailable: ${err.message}. You can still contact owner without location.`);
    });
  }

  async function sendSighting(){
    setLoading(true);
    // In production, POST to /api/finder/sighting with token (signed, device-bound, nonce, expiry, replay-protected)
    await new Promise(r=>setTimeout(r,600));
    setMsg('Sighting sent. Owner has been notified (push + activity). Thank you for helping recovery.');
    setLoading(false);
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-background">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">🔴 Device Reported Lost</CardTitle>
          <CardDescription>This device has been reported lost. Recovery ID: {token.slice(0,8).toUpperCase()}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="rounded-lg border p-4 bg-muted/30">
            <p className="text-sm">You scanned a RETRACE recovery QR. No app or account required.</p>
            <p className="text-xs text-muted-foreground mt-2">QR contains a short-lived signed token (device-bound, nonce, replay-protected, expirable). Never a permanent credential.</p>
          </div>

          <div className="space-y-2">
            <p className="text-sm font-medium">Help the owner</p>
            <Button onClick={requestLocation} variant="secondary" className="w-full">Share my location (optional)</Button>
            {locationGranted && coords && <p className="text-xs text-muted-foreground">Captured: {coords.lat.toFixed(5)}, {coords.lng.toFixed(5)} • ±?m</p>}
            <p className="text-xs text-muted-foreground">Owner does not automatically receive your identity/phone unless you choose to share it.</p>
          </div>

          <div>
            <Label htmlFor="contact">Contact info to share (optional)</Label>
            <Input id="contact" value={contact} onChange={e=>setContact(e.target.value)} placeholder="Phone or email — only if you want owner to contact you" />
          </div>

          <Button onClick={sendSighting} loading={loading} className="w-full">Send Sighting</Button>
          {msg && <p role="status" className="text-sm border rounded-lg p-3 bg-muted">{msg}</p>}

          <div className="rounded-lg border p-3">
            <p className="text-xs font-medium">Rescue (connectivity help)</p>
            <p className="text-xs text-muted-foreground mt-1">Rescue never forces hotspot/data/quota without consent. Tier 1 = automatic if OS allows. Tier 2 = consent prompt. Tier 3 = fallback (finder location + QR event + offline queue).</p>
            <Button variant="ghost" size="sm" className="mt-2 w-full" onClick={()=>setMsg('Rescue is consent-gated, temporary, limited, and recovery-only. Priority: 1 Location 2 Security 3 Device status 4 Recovery 5 Evidence 6 History.')}>Learn about Rescue</Button>
          </div>

          <p className="text-xs text-muted-foreground text-center">By using this page you agree to help recovery. Abuse is rate-limited and audited.</p>
        </CardContent>
      </Card>
    </div>
  );
}
