'use client';
import { useEffect, useState } from 'react';
import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input, Label } from '@/components/ui/input';
import { Badge, StatusBadge } from '@/components/ui/badge';
import { supabase } from '@/lib/supabase';

type Device = { id:string; name:string; brand:string|null; model:string|null; retrace_device_id:string; state:string; lost_state:string; battery_level:number|null; is_online:boolean|null };

export default function DevicesPage(){
  const [devices,setDevices]=useState<Device[]>([]);
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState<string|null>(null);
  const [form,setForm]=useState({ name:'', brand:'', model:'', os:'Android', serial_number:'' });
  const [creating,setCreating]=useState(false);

  async function load(){
    setLoading(true); setError(null);
    const { data, error } = await supabase.from('devices').select('id,name,brand,model,retrace_device_id,state,lost_state,battery_level,is_online').order('created_at',{ascending:false});
    if (error) setError(error.message); else setDevices((data as Device[])??[]);
    setLoading(false);
  }
  useEffect(()=>{ load(); },[]);

  async function onCreate(e:React.FormEvent){
    e.preventDefault();
    if (!form.name.trim()) return;
    setCreating(true);
    const retraceId = `RT-${Math.random().toString(36).slice(2,8).toUpperCase()}-${Date.now().toString(36).toUpperCase()}`;
    const cryptoId = `cr_${Array.from(crypto.getRandomValues(new Uint8Array(16))).map(b=>b.toString(16).padStart(2,'0')).join('')}`;
    const { error } = await supabase.from('devices').insert({
      name: form.name, brand: form.brand || null, model: form.model || null, os: form.os, serial_number: form.serial_number || null,
      retrace_device_id: retraceId, cryptographic_identity: cryptoId, state:'PENDING'
    });
    if (error) setError(error.message); else { setForm({ name:'', brand:'', model:'', os:'Android', serial_number:'' }); await load(); }
    setCreating(false);
  }

  return (
    <AppShell>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div><h1 className="text-2xl font-bold tracking-tight">Devices</h1><p className="text-sm text-muted-foreground">Add Device → Identity (RETRACE ID + crypto binding + IMEI metadata) → Permissions</p></div>
          <Badge variant="outline">{devices.length} device(s)</Badge>
        </div>

        <Card>
          <CardHeader><CardTitle>Add Device</CardTitle></CardHeader>
          <CardContent>
            <form onSubmit={onCreate} className="grid grid-cols-1 md:grid-cols-6 gap-3">
              <div className="md:col-span-2"><Label>Device Name *</Label><Input value={form.name} onChange={e=>setForm({...form,name:e.target.value})} placeholder="My Galaxy A55" required /></div>
              <div><Label>Brand</Label><Input value={form.brand} onChange={e=>setForm({...form,brand:e.target.value})} placeholder="Samsung" /></div>
              <div><Label>Model</Label><Input value={form.model} onChange={e=>setForm({...form,model:e.target.value})} placeholder="SM-A556" /></div>
              <div><Label>OS</Label><Input value={form.os} onChange={e=>setForm({...form,os:e.target.value})} placeholder="Android" /></div>
              <div><Label>Serial (optional)</Label><Input value={form.serial_number} onChange={e=>setForm({...form,serial_number:e.target.value})} placeholder="—" /></div>
              <div className="md:col-span-6 flex gap-2">
                <Button type="submit" loading={creating}>Register Device</Button>
                <p className="text-xs text-muted-foreground self-center">IMEI is supplementary, not primary identity. Primary is RETRACE Device ID + cryptographic binding + metadata (brand/model/OS/imei1/imei2/serial/phone/photo/purchase). See PRD 6-7.</p>
              </div>
            </form>
            {error && <p role="alert" className="mt-3 text-sm text-destructive bg-destructive/10 border rounded-lg px-3 py-2">{error}</p>}
          </CardContent>
        </Card>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">{[1,2].map(i=> <div key={i} className="h-32 rounded-xl bg-muted animate-pulse" />)}</div>
        ) : devices.length===0 ? (
          <Card><CardContent className="p-8 text-center"><p className="font-medium">No devices yet</p><p className="text-sm text-muted-foreground mt-1">Register a device to enable tracking, lost mode, and finder recovery. Every state handles Loading/Empty/Error/Offline.</p></CardContent></Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {devices.map(d=>(
              <Card key={d.id} className="hover:shadow-sm transition-shadow">
                <CardContent className="p-4 space-y-3">
                  <div className="flex items-start justify-between gap-3">
                    <div><p className="font-semibold">{d.name}</p><p className="text-xs text-muted-foreground">{[d.brand,d.model].filter(Boolean).join(' • ') || 'No brand/model'}</p><p className="text-xs font-mono text-muted-foreground mt-1">{d.retrace_device_id}</p></div>
                    <StatusBadge status={d.state} />
                  </div>
                  <div className="flex items-center gap-2 text-xs">
                    <Badge variant={d.is_online ? 'success' : 'outline'}>{d.is_online ? 'ONLINE' : 'OFFLINE'}</Badge>
                    <Badge variant="outline">{d.lost_state}</Badge>
                    {d.battery_level!=null && <span className="text-muted-foreground">{Math.round(d.battery_level)}%</span>}
                  </div>
                  <div className="flex gap-2">
                    <a href={`/devices/${d.id}`} className="btn-secondary btn-sm text-xs">View • Map • Commands • Activity • Evidence</a>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </AppShell>
  );
}
