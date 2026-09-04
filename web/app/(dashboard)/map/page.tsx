'use client';
import { useEffect, useState } from 'react';
import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { RetraceMap } from '@/components/map/retrace-map';
import { supabase } from '@/lib/supabase';

export default function MapPage(){
  const [points,setPoints]=useState<any[]>([]);
  const [loading,setLoading]=useState(true);
  useEffect(()=>{
    (async()=>{
      const { data } = await supabase.from('device_locations').select('latitude,longitude,accuracy,source,confidence,device_timestamp').order('device_timestamp',{ascending:false}).limit(30);
      setPoints((data??[]).map((d:any)=>({ lat:Number(d.latitude), lng:Number(d.longitude), accuracy:d.accuracy, source:d.source, confidence:d.confidence, label:`${d.source} ${d.confidence}` })));
      setLoading(false);
    })();
  },[]);
  return (
    <AppShell>
      <Card>
        <CardHeader><CardTitle>Live Map — all devices</CardTitle></CardHeader>
        <CardContent>{loading ? <div className="h-[420px] rounded-xl bg-muted animate-pulse" /> : <RetraceMap points={points} />}</CardContent>
      </Card>
      <p className="text-xs text-muted-foreground mt-2">Provider-agnostic abstraction (Leaflet default). Accuracy circle, history route, finder sightings, follow mode, recenter, navigation handoff, dark/satellite where available.</p>
    </AppShell>
  );
}
