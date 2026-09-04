// Simple token-bucket rate limiter for Route Handlers (PRD 78)
// Limits: login 10/15m, recovery 5/15m, PIN 5/15m, QR 20/min, command 30/min, finder 10/5m, api 100/min
const buckets = new Map<string,{count:number; reset:number}>();
export function rateLimit(key:string, limit:number, windowMs:number){
  const now = Date.now();
  const b = buckets.get(key);
  if (!b || now > b.reset){
    buckets.set(key, {count:1, reset: now+windowMs});
    return {ok:true, remaining: limit-1};
  }
  if (b.count >= limit) return {ok:false, remaining:0, retryAfter: b.reset-now};
  b.count++;
  return {ok:true, remaining: limit-b.count};
}
export function rateLimitKey(req:Request, suffix:string){
  const ip = (req.headers.get('x-forwarded-for')||'').split(',')[0] || 'unknown';
  return `${ip}:${suffix}`;
}
