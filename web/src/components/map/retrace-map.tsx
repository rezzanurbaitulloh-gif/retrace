'use client';
import { useEffect, useState } from 'react';
import dynamic from 'next/dynamic';
import { accuracyLabel } from '@/lib/utils';

const MapContainer = dynamic(()=> import('react-leaflet').then(m=> m.MapContainer), { ssr:false }) as any;
const TileLayer = dynamic(()=> import('react-leaflet').then(m=> m.TileLayer), { ssr:false }) as any;
const Marker = dynamic(()=> import('react-leaflet').then(m=> m.Marker), { ssr:false }) as any;
const Circle = dynamic(()=> import('react-leaflet').then(m=> m.Circle), { ssr:false }) as any;
const Popup = dynamic(()=> import('react-leaflet').then(m=> m.Popup), { ssr:false }) as any;

export interface MapPoint { lat:number; lng:number; accuracy?:number|null; label?:string; confidence?:string; source?:string; timestamp?:string }

export function RetraceMap({ points, center, zoom=13, onRecenter }:{ points: MapPoint[]; center?: [number,number]; zoom?:number; onRecenter?:()=>void }){
  const [mounted,setMounted]=useState(false);
  useEffect(()=>{ setMounted(true); },[]);
  if (!mounted) return <div className="h-[420px] w-full rounded-xl bg-muted animate-pulse flex items-center justify-center text-sm text-muted-foreground">Loading map…</div>;
  const mapCenter = center ?? (points[0] ? [points[0].lat, points[0].lng] as [number,number] : [-6.2088,106.8456]);
  return (
    <div className="relative overflow-hidden rounded-xl border">
      <MapContainer center={mapCenter} zoom={zoom} style={{height:420, width:'100%'}}>
        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" attribution="&copy; OpenStreetMap" />
        {points.map((p,i)=>(
          <div key={i}>
            <Marker position={[p.lat,p.lng]}>{p.label && <Popup>{p.label}<br/>{accuracyLabel(p.accuracy)} • {p.source} • {p.confidence}</Popup>}</Marker>
            {p.accuracy && <Circle center={[p.lat,p.lng]} radius={p.accuracy} pathOptions={{ color:'#16a34a', fillColor:'#22c55e', fillOpacity:0.15 }} />}
          </div>
        ))}
      </MapContainer>
      <div className="absolute bottom-3 left-3 right-3 flex items-center justify-between gap-2 pointer-events-none">
        <div className="pointer-events-auto bg-surface/95 backdrop-blur border rounded-lg px-3 py-1.5 text-xs flex items-center gap-2">
          <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" aria-hidden="true" />
          {points.length>0 ? `${points.length} point(s) • ${accuracyLabel(points[0].accuracy)}` : 'No location yet'}
        </div>
        {onRecenter && <button onClick={onRecenter} className="pointer-events-auto bg-surface border rounded-lg px-3 py-1.5 text-xs font-medium hover:bg-muted">Recenter</button>}
      </div>
    </div>
  );
}
export function MapPlaceholder({message}:{message?:string}){ return <div className="h-[420px] w-full rounded-xl border bg-muted flex flex-col items-center justify-center gap-2 p-6 text-center"><p className="text-sm font-medium">{message ?? 'Map unavailable'}</p><p className="text-xs text-muted-foreground">Last known location will appear when available. Offline queue syncs when connection restores.</p></div>; }
