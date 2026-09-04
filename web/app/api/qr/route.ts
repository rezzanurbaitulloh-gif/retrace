import { NextResponse } from 'next/server';
import { getServerSupabase, getServiceSupabase } from '@/lib/supabase';
import crypto from 'crypto';
import { rateLimit, rateLimitKey } from '@/lib/rate-limit';

// POST /api/qr — generate short-lived signed token for a lost device
export async function POST(req: Request){
  const rl = rateLimit(rateLimitKey(req,'qr'), 20, 60_000);
  if (!rl.ok) return NextResponse.json({ error:'Rate limited' },{status:429});
  const supabase = await getServerSupabase();
  const { data:{user} } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error:'Unauthorized' },{status:401});
  const { device_id, lost_case_id } = await req.json();
  if (!device_id || !lost_case_id) return NextResponse.json({ error:'device_id and lost_case_id required' },{status:400});
  // Verify ownership via RLS (or explicit check)
  const { data: device } = await supabase.from('devices').select('id,user_id').eq('id',device_id).single();
  if (!device || (device as any).user_id !== user.id) return NextResponse.json({ error:'Forbidden' },{status:403});
  const service = getServiceSupabase();
  const nonce = crypto.randomBytes(16).toString('hex');
  const expiresAt = new Date(Date.now()+ 60*60*1000).toISOString(); // 1h per AppConfig
  const payload = { device_id, lost_case_id, nonce, exp: expiresAt };
  const secret = process.env.QR_SIGNING_SECRET ?? 'dev-secret-change-me';
  const token = crypto.createHmac('sha256', secret).update(JSON.stringify(payload)).digest('hex').slice(0,32);
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  await service.from('qr_tokens').insert({ device_id, lost_case_id, token_hash: tokenHash, nonce, signed_payload: payload, expires_at: expiresAt, max_scans:1 });
  return NextResponse.json({ token, expires_at: expiresAt, recovery_url: `${process.env.NEXT_PUBLIC_APP_URL ?? ''}/finder/${token}` });
}
