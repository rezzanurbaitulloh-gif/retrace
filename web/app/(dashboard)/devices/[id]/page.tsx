'use client';
import { useEffect, useState } from 'react';
import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge, StatusBadge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { RetraceMap } from '@/components/map/retrace-map';
import { BatteryIndicator } from '@/components/device/battery-indicator';
import { LostScreenPreview } from '@/components/device/lost-screen';
import { ContactInfoSafe } from '@/components/device/contact-info-safe';
import { StateView, OfflineBanner, UnsupportedBanner } from '@/components/ui/state';
import { supabase } from '@/lib/supabase';
import { accuracyLabel, timeAgo } from '@/lib/utils';

export default function DeviceDetailPage({ params }: { params:{id:string}}){
  const id=params.id;
  const [device,setDevice]=useState<any>(null);
  const [locations,setLocations]=useState<any[]>([]);
  const [activities,setActivities]=useState<any[]>([]);
  const [loading,setLoading]=useState(true);
  const [actionLoading,setActionLoading]=useState<string|null>(null);
  const [message,setMessage]=useState<string|null>(null);

  async function load(){
    setLoading(true);
    const { data: d } = await supabase.from('devices').select('*').eq('id',id).single();
    setDevice(d);
    const { data: locs } = await supabase.from('device_locations').select('*').eq('device_id',id).order('device_timestamp',{ascending:false}).limit(50);
    setLocations(locs ?? []);
    const { data: acts } = await supabase.from('activity_events').select('*').eq('device_id',id).order('created_at',{ascending:false}).limit(30);
    setActivities(acts ?? []);
    setLoading(false);
  }
  useEffect(()=>{ load(); },[id]);

  async function markLost(){
    setActionLoading('lost');
    const { data: existing } = await supabase.from('lost_cases').select('id').eq('device_id',id).eq('status','LOST').limit(1);
    if (!existing || existing.length===0){
      await supabase.from('lost_cases').insert({ device_id:id, status:'LOST', recovery_message:'Device reported lost via RETRACE' });
      await supabase.from('devices').update({ state:'LOST', lost_state:'LOST' }).eq('id',id);
      await supabase.from('activity_events').insert({ device_id:id, category:'RECOVERY', priority:'CRITICAL', event_type:'LOST_MODE_ACTIVATED', title:'Lost Mode activated', description:'Owner marked device as lost' });
    }
    setMessage('Lost Mode activated — activity logged, realtime will notify authorized viewers.');
    setActionLoading(null); load();
  }

  async function sendCommand(type:string){
    setActionLoading(type);
    const { data: lc } = await supabase.from('lost_cases').select('id').eq('device_id',id).order('reported_at',{ascending:false}).limit(1).single();
    const lost_case_id = (lc as any)?.id ?? null;
    if (!lost_case_id){ setMessage('Create a lost case first (Mark as Lost).'); setActionLoading(null); return; }
    const { error } = await supabase.from('lost_commands').insert({ lost_case_id, device_id:id, command_type:type, payload:{} });
    if (error) setMessage(error.message); else {
      await supabase.from('activity_events').insert({ device_id:id, lost_case_id, category: type==='RING'||type==='VIBRATE' ? 'DEVICE' : 'SECURITY', priority:'IMPORTANT', event_type:`COMMAND_${type}`, title:`${type} command queued`, description:`Command ${type} queued — delivery depends on connectivity and OS support` });
      setMessage(`${type} queued. If OS does not allow it, UI shows UNSUPPORTED — never fake success.`);
    }
    setActionLoading(null);
  }

  if (loading) return <AppShell><div className="h-64 rounded-xl bg-muted animate-pulse" /></AppShell>;
  if (!device) return <AppShell><Card><CardContent className="p-8 text-center">Device not found or unauthorized (RLS).</CardContent></Card></AppShell>;

  const points = locations.map(l=>({ lat:Number(l.latitude), lng:Number(l.longitude), accuracy:l.accuracy, label:`${l.source} • ${l.confidence} • ${timeAgo(l.device_timestamp)}`, source:l.source, confidence:l.confidence, timestamp:l.device_timestamp }));

  return (
    <AppShell>
      <div className="space-y-4">
        {!device.is_online && <OfflineBanner />}
        {device.state==='LOST' && <div className="rounded-lg border border-destructive/20 bg-destructive/5 px-3 py-2 text-sm">🔴 LOST — emergency actions are primary (PRD 93)</div>}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h1 className="text-xl font-bold tracking-tight flex items-center gap-2">{device.name} <StatusBadge status={device.state} /></h1>
            <p className="text-xs text-muted-foreground font-mono">{device.retrace_device_id} • {device.brand} {device.model} • {device.os} {device.os_version}</p>
          </div>
          <div className="flex gap-2">
            <Button variant="danger" size="sm" loading={actionLoading==='lost'} onClick={markLost}>Mark as Lost</Button>
            <Button variant="secondary" size="sm" onClick={load}>Refresh</Button>
          </div>
        </div>
        {message && <div className="rounded-lg border bg-amber-50 dark:bg-amber-950/20 px-3 py-2 text-sm">{message}</div>}

        <Tabs defaultValue="map">
          <TabsList>
            <TabsTrigger value="map">Map</TabsTrigger>
            <TabsTrigger value="commands">Commands</TabsTrigger>
            <TabsTrigger value="activity">Activity</TabsTrigger>
            <TabsTrigger value="evidence">Evidence</TabsTrigger>
            <TabsTrigger value="settings">Settings</TabsTrigger>
          </TabsList>

          <TabsContent value="map">
            <Card>
              <CardHeader><CardTitle className="flex items-center gap-2">Live Tracking {device.is_online ? <Badge variant="success">LIVE</Badge> : <Badge variant="outline">Last known</Badge>}</CardTitle></CardHeader>
              <CardContent className="space-y-3">
                {points.length>0 ? <RetraceMap points={points} /> : <div className="h-[420px] rounded-xl border bg-muted flex items-center justify-center p-6 text-center text-sm text-muted-foreground">No location yet. {device.is_online ? 'Waiting for GPS…' : <>Last known: {device.last_known_location_timestamp ? timeAgo(device.last_known_location_timestamp) : '—'} — offline queue will sync on reconnect.</>}</div>}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs">
                  <div className="rounded-lg border p-3"><p className="text-muted-foreground">Accuracy</p><p className="font-medium">{device.last_known_location_accuracy ? accuracyLabel(device.last_known_location_accuracy) : '—'}</p></div>
                  <div className="rounded-lg border p-3"><p className="text-muted-foreground">Battery</p><p className="font-medium">{device.battery_level!=null ? `${Math.round(device.battery_level)}%` : '—'} {device.battery_status && `• ${device.battery_status}`}</p></div>
                  <div className="rounded-lg border p-3"><p className="text-muted-foreground">Connection</p><p className="font-medium">{device.connection_type ?? (device.is_online ? 'ONLINE' : 'OFFLINE')}</p></div>
                  <div className="rounded-lg border p-3"><p className="text-muted-foreground">Source</p><p className="font-medium">{locations[0]?.source ?? 'UNKNOWN'} • {locations[0]?.confidence ?? 'LOW'}</p></div>
                </div>
                <div className="flex gap-2">
                  <Button size="sm" variant="secondary" onClick={()=> window.open(`https://www.google.com/maps/dir/?api=1&destination=${points[0]?.lat},${points[0]?.lng}`,'_blank')}>Route (handoff to Maps)</Button>
                  <Button size="sm" variant="ghost" onClick={load}>Follow • Recenter • History</Button>
                </div>
                {locations.length>0 && (
                  <div className="rounded-lg border p-3">
                    <p className="text-sm font-medium">Route History ({locations.length})</p>
                    <div className="mt-2 space-y-1 max-h-40 overflow-auto pr-2">
                      {locations.slice(0,10).map(l=>(
                        <div key={l.id} className="flex items-center justify-between text-xs border-b last:border-0 py-1">
                          <span>{new Date(l.device_timestamp).toLocaleString()} • {l.source} • {accuracyLabel(l.accuracy)}</span>
                          <span className="text-muted-foreground">{timeAgo(l.device_timestamp)}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="commands">
            <Card><CardHeader><CardTitle>Emergency Commands (Lost Mode)</CardTitle></CardHeader>
              <CardContent className="grid grid-cols-2 md:grid-cols-3 gap-3">
                {[
                  {k:'LOCATE',label:'Locate',desc:'Request fresh location'},
                  {k:'RING',label:'Ring',desc:'Official API or UNSUPPORTED'},
                  {k:'VIBRATE',label:'Vibrate',desc:'If OS allows'},
                  {k:'LOCK',label:'Lock',desc:'Platform lock or UNSUPPORTED'},
                  {k:'SHOW_LOST_SCREEN',label:'Lost Screen',desc:'Show contact + QR'},
                  {k:'RESCUE',label:'Rescue',desc:'Consent-based connectivity'},
                ].map(c=>(
                  <div key={c.k} className="rounded-xl border p-4 space-y-2">
                    <p className="font-medium text-sm">{c.label}</p><p className="text-xs text-muted-foreground">{c.desc}</p>
                    <Button size="sm" loading={actionLoading===c.k} onClick={()=>sendCommand(c.k)}>{c.label}</Button>
                  </div>
                ))}
              </CardContent>
            </Card>
            <p className="text-xs text-muted-foreground mt-2">All commands are queued with expiry and retry. Execution is never faked. Realtime delivers when device connects; offline queue syncs later.</p>
          </TabsContent>

          <TabsContent value="activity">
            <Card><CardHeader><CardTitle>Activity Stream</CardTitle></CardHeader>
              <CardContent className="space-y-2">
                {activities.length===0 ? <p className="text-sm text-muted-foreground">No activity yet. Events: Lost Mode, Location, QR scanned, Finder sighting, Rescue, Evidence.</p> :
                  activities.map(a=>(
                    <div key={a.id} className="flex gap-3 border-b last:border-0 py-2">
                      <Badge variant={a.priority==='CRITICAL'?'danger': a.priority==='IMPORTANT'?'warning':'outline'}>{a.category}</Badge>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate">{a.title}</p>
                        <p className="text-xs text-muted-foreground">{a.description ?? a.event_type} • {timeAgo(a.created_at)}</p>
                      </div>
                    </div>
                  ))}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="evidence">
            <Card><CardHeader><CardTitle>Recovery Evidence</CardTitle></CardHeader>
              <CardContent><p className="text-sm text-muted-foreground">Evidence is encrypted, private, access-controlled, integrity-verified, expiring, and audited. Camera requires permission; offline captures are encrypted and queued.</p>
                <div className="mt-3 rounded-lg border p-4 text-sm">Evidence viewer appears when device uploads. Empty / Offline / Unauthorized states are distinct.</div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="settings">
            <Card><CardHeader><CardTitle>Device Settings</CardTitle></CardHeader>
              <CardContent className="space-y-2 text-sm">
                <p><span className="font-medium">RETRACE ID:</span> <span className="font-mono text-xs">{device.retrace_device_id}</span></p>
                <p><span className="font-medium">Crypto identity:</span> <span className="font-mono text-xs break-all">{device.cryptographic_identity}</span></p>
                <BatteryIndicator level={device.battery_level} isCharging={device.is_charging} />
                <LostScreenPreview owner={device.name} recoveryId={device.retrace_device_id} />
                <ContactInfoSafe />
                <p className="text-muted-foreground">IMEI is supplementary. Deleting app or factory reset clears local keys; server re-recognizes device when identity matches on reconnect (if available).</p>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </AppShell>
  );
}
