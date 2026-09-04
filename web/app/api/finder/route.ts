import { NextResponse } from 'next/server';
import { getServiceSupabase } from '@/lib/supabase';
import crypto from 'crypto';

export async function POST(req: Request){
  const { token, latitude, longitude, accuracy, contact_info } = await req.json();
  if (!token) return NextResponse.json({ error:'token required' },{status:400});
  const service = getServiceSupabase();
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  const { data: qr } = await service.from('qr_tokens').select('*').eq('token_hash', tokenHash).single();
  if (!qr || new Date((qr as unknown as {expires_at:string}).expires_at) < new Date()) return NextResponse.json({ error:'Invalid or expired token' },{status:400});
  const q = qr as unknown as {id:string; device_id:string; lost_case_id:string; scan_count:number|null; max_scans:number|null; used_at:string|null; expires_at:string};
  if (q.used_at && (q.max_scans ?? 1) <= (q.scan_count ?? 0)) return NextResponse.json({ error:'Token already used' },{status:409});
  await service.from('finder_sessions').insert({
    lost_case_id: q.lost_case_id,
    qr_token_id: q.id,
    finder_location: latitude && longitude ? `POINT(${longitude} ${latitude})` : null,
    finder_location_accuracy: accuracy ?? null,
    contact_info_shared: contact_info ?? {},
    sighting_reported: true,
    reported_at: new Date().toISOString(),
    expires_at: new Date(Date.now()+ 24*60*60*1000).toISOString()
  });
  await service.from('qr_tokens').update({ scan_count: (q.scan_count ?? 0)+1, used_at: new Date().toISOString(), used_by_finder:true }).eq('id',q.id);
  await service.from('activity_events').insert({ device_id:q.device_id, lost_case_id:q.lost_case_id, category:'FINDER', priority:'CRITICAL', event_type:'QR_SCANNED', title:'QR scanned — finder sighting received', description: latitude ? `Finder reported at ${latitude},${longitude}` : 'Finder scanned QR' });
  return NextResponse.json({ ok:true, message:'Sighting recorded. Owner notified.' });
}
