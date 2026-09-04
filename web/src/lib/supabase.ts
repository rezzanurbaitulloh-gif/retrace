import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { createBrowserClient, createServerClient } from '@supabase/ssr';
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
if (!supabaseUrl || !supabaseAnonKey) console.warn('[retrace] Missing supabase env');
export const supabase = createBrowserClient(supabaseUrl ?? '', supabaseAnonKey ?? '', {
  auth: { persistSession:true, autoRefreshToken:true, detectSessionInUrl:true },
});
export type { SupabaseClient };
export async function getServerSupabase(): Promise<SupabaseClient> {
  const { cookies } = await import('next/headers');
  const cookieStore = await cookies();
  return createServerClient(supabaseUrl ?? '', supabaseAnonKey ?? '', {
    cookies: {
      getAll(){ return cookieStore.getAll(); },
      setAll(cookiesToSet: Array<{name:string;value:string;options?:Record<string,unknown>}>) {
        try { cookiesToSet.forEach(({name,value,options})=> cookieStore.set(name,value,options as any)); } catch {}
      }
    }
  });
}
export function getServiceSupabase(): SupabaseClient {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!key) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY');
  return createClient(supabaseUrl ?? '', key, { auth:{ autoRefreshToken:false, persistSession:false }});
}
export function geographyToLngLat(wkb: string | null | undefined): [number,number] | null {
  if (!wkb || typeof wkb!=='string') return null;
  try {
    const buf = Buffer.from(wkb,'hex');
    const le = buf[0]===1;
    const read=(off:number)=>{ const b=buf.slice(off,off+8); if(le) b.reverse(); return b.readDoubleBE(0); };
    const x=read(5), y=read(13);
    if (!Number.isFinite(x)||!Number.isFinite(y)) return null;
    return [x,y];
  } catch { return null; }
}
