import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const PROTECTED = ['/dashboard','/devices','/map','/recovery','/activity','/trusted','/profile','/admin'];
const AUTH_ONLY = ['/login','/signup','/forgot-password'];
function matches(pathname:string, prefixes:string[]){ return prefixes.some(p=> pathname===p || pathname.startsWith(`${p}/`)); }
export async function middleware(request: NextRequest){
  let response = NextResponse.next({ request });
  const supabase = createServerClient(supabaseUrl, supabaseAnonKey, {
    cookies: {
      getAll(){ return request.cookies.getAll(); },
      setAll(cookiesToSet: Array<{name:string;value:string;options?:Record<string,unknown>}>) {
        cookiesToSet.forEach(({name,value})=> request.cookies.set(name,value));
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({name,value,options})=> response.cookies.set(name,value,options as any));
      }
    }
  });
  const { data:{user} } = await supabase.auth.getUser();
  const { pathname } = request.nextUrl;
  if (matches(pathname, PROTECTED) && !user){ const url=request.nextUrl.clone(); url.pathname='/login'; url.searchParams.set('redirectedFrom',pathname); return NextResponse.redirect(url); }
  if (matches(pathname, AUTH_ONLY) && user){ const url=request.nextUrl.clone(); url.pathname='/dashboard'; url.search=''; return NextResponse.redirect(url); }
  return response;
}
export const config={ matcher:['/((?!_next/static|_next/image|favicon.ico|manifest.json|icon.svg|.*\\.(?:svg|png|jpg|jpeg|gif|webp|css|js)$).*)'] };
