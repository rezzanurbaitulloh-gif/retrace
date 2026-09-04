'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
const NAV=[
  { href:'/dashboard', label:'Home', icon:'H' },
  { href:'/devices', label:'Devices', icon:'D' },
  { href:'/map', label:'Map', icon:'M' },
  { href:'/recovery', label:'Recovery', icon:'R' },
  { href:'/activity', label:'Activity', icon:'A' },
  { href:'/trusted', label:'Trusted', icon:'T' },
  { href:'/profile', label:'Profile', icon:'P' },
];
export function AppShell({children}:{children:React.ReactNode}){
  const pathname=usePathname();
  return (
    <div className="min-h-screen bg-background flex flex-col">
      <header className="sticky top-0 z-40 w-full border-b bg-surface/95 backdrop-blur supports-[backdrop-filter]:bg-surface/60">
        <div className="max-w-[1400px] mx-auto flex h-14 items-center justify-between px-4">
          <Link href="/dashboard" className="flex items-center gap-2 font-bold text-lg tracking-tight"><span className="h-7 w-7 rounded-lg bg-primary flex items-center justify-center text-primary-foreground text-xs">R</span>RETRACE</Link>
          <nav className="hidden md:flex items-center gap-1">
            {NAV.map(n=>{ const active=pathname===n.href||pathname.startsWith(n.href+'/'); return <Link key={n.href} href={n.href} className={cn('px-3 py-1.5 rounded-lg text-sm font-medium transition-colors', active?'bg-muted text-foreground':'text-muted-foreground hover:text-foreground hover:bg-muted/50')}>{n.label}</Link>; })}
          </nav>
          <div className="flex items-center gap-2">
            <Link href="/profile" className="h-8 w-8 rounded-full bg-muted flex items-center justify-center text-xs font-medium">U</Link>
          </div>
        </div>
      </header>
      <nav className="md:hidden border-b bg-surface sticky top-14 z-30 overflow-x-auto">
        <div className="flex gap-1 p-2">
          {NAV.map(n=>{ const active=pathname===n.href; return <Link key={n.href} href={n.href} className={cn('px-3 py-1.5 rounded-full text-sm font-medium whitespace-nowrap', active?'bg-primary text-primary-foreground':'bg-muted text-muted-foreground')}>{n.label}</Link>; })}
        </div>
      </nav>
      <main className="flex-1 max-w-[1400px] w-full mx-auto px-4 py-6">{children}</main>
      <footer className="border-t py-4 text-center text-xs text-muted-foreground">RETRACE — Platform Honest • Offline First • Recovery First • <Link href="/docs" className="underline">Docs</Link></footer>
    </div>
  );
}
