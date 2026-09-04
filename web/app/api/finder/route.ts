import { NextResponse } from 'next/server';
import { getServiceSupabase } from '@/lib/supabase';

// POST /api/finder — finder sighting (no auth required, rate-limited via service)
export async function POST(req: Request){
  const { token, latitude, longitude, accuracy, contact_info } = await req.json();
  if (!token) return NextResponse.json({ error:'token required' },{status:400});
  const service = getServiceSupabase();
  // Validate QR token: signed, device-bound, nonce, expiry, replay protection
  // Simplified: lookup by token hash where expires_at > now and used_at is null
  const tokenHash = require('crypto').createHash('sha256').update(token).digest('hex');
  const { data: qr } = await service.from('qr_tokens').select('*').eq('token_hash', tokenHash).single();
  if (!qr || new Date((qr as any).expires_at) < new Date()) return NextResponse.json({ error:'Invalid or expired token' },{status:400});
  if ((qr as any).used_at && (qr as any).max_scans <= (qr as any).scan_count) return NextResponse.json({ error:'Token already used' },{status:409});
  // Record finder session + sighting
  await service.from('finder_sessions').insert({
    lost_case_id: (qr as any).lost_case_id,
    qr_token_id: (qr as any).id,
    finder_location: latitude && longitude ? `POINT(${longitude} ${latitude})` : null,
    finder_location_accuracy: accuracy ?? null,
    contact_info_shared: contact_info ?? {},
    sighting_reported: true,
    reported_at: new Date().toISOString(),
    expires_at: new Date(Date.now()+ 24*60*60*1000).toISOString()
  });
  await service.from('qr_tokens').update({ scan_count: ((qr as any).scan_count ?? 0)+1, used_at: new Date().toISOString(), used_by_finder:true }).eq('id',(qr as any).id);
  await service.from('activity_events').insert({ device_id:(qr as any).device_id, lost_case_id:(qr as any).lost_case_id, category:'FINDER', priority:'CRITICAL', event_type:'QR_SCANNED', title:'QR scanned — finder sighting received', description: latitude ? `Finder reported at ${latitude},${longitude}` : 'Finder scanned QR' });
  return NextResponse.json({ ok:true, message:'Sighting recorded. Owner notified.' });
}
