'use client';
import { useEffect, useState } from 'react';
import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { supabase } from '@/lib/supabase';
import { timeAgo } from '@/lib/utils';

export default function ActivityPage(){
  const [events,setEvents]=useState<any[]>([]);
  const [filter,setFilter]=useState<string>('ALL');
  useEffect(()=>{ (async()=>{
    const { data } = await supabase.from('activity_events').select('*').order('created_at',{ascending:false}).limit(100);
    setEvents(data??[]);
  })(); },[]);
  const filtered = filter==='ALL' ? events : events.filter(e=> e.category===filter);
  return (
    <AppShell>
      <Card>
        <CardHeader><CardTitle>Activity Stream</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          <div className="flex gap-1 flex-wrap">
            {['ALL','SECURITY','LOCATION','DEVICE','RECOVERY','FINDER','RESCUE','EVIDENCE','SYSTEM','ADMIN'].map(c=>(
              <button key={c} onClick={()=>setFilter(c)} className={`px-3 py-1 rounded-full text-xs border ${filter===c?'bg-primary text-primary-foreground':'bg-muted'}`}>{c}</button>
            ))}
          </div>
          <div className="space-y-2">
            {filtered.length===0 ? <p className="text-sm text-muted-foreground">No events. Every important recovery event appears here (Lost Mode, command, location, offline/online, QR scan, finder sighting, rescue, evidence, battery, security).</p> :
              filtered.map(e=>(
                <div key={e.id} className="flex gap-3 border rounded-lg p-3">
                  <Badge variant={e.priority==='CRITICAL'?'danger': e.priority==='IMPORTANT'?'warning':'outline'}>{e.priority}</Badge>
                  <div className="flex-1"><p className="text-sm font-medium">{e.title}</p><p className="text-xs text-muted-foreground">{e.category} • {e.event_type} • {timeAgo(e.created_at)}</p></div>
                </div>
              ))}
          </div>
          <p className="text-xs text-muted-foreground">Notifications are aggregated: &quot;Device moved 450m&quot; not &quot;Location update #492&quot;.</p>
        </CardContent>
      </Card>
    </AppShell>
  );
}
