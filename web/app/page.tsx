import Link from 'next/link';
export default function HomePage(){
  return (
    <main className="min-h-screen flex flex-col">
      <header className="border-b bg-surface/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-2">
              <span className="h-8 w-8 rounded-lg bg-primary flex items-center justify-center text-primary-foreground font-bold text-xs">R</span>
              <span className="text-xl font-bold tracking-tight">RETRACE</span>
            </div>
            <nav className="flex items-center gap-3">
              <Link href="/login" className="btn-ghost">Sign In</Link>
              <Link href="/signup" className="btn-primary">Get Started</Link>
            </nav>
          </div>
        </div>
      </header>
      <section className="flex-1 flex items-center justify-center py-20 px-4">
        <div className="max-w-5xl mx-auto text-center">
          <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-muted text-muted-foreground text-sm font-medium mb-8">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" aria-hidden="true" /> Platform Honest • Offline First • Recovery First
          </span>
          <h1 className="text-5xl sm:text-6xl font-bold tracking-tight mb-6">Complete Device <span className="text-primary">Recovery</span> Ecosystem</h1>
          <p className="text-xl text-muted-foreground max-w-3xl mx-auto mb-10 leading-relaxed">Find and secure lost devices across online, offline, Wi-Fi-only, and limited-connectivity scenarios. No fake capabilities. No stalking vectors. Just honest recovery.</p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16">
            <Link href="/signup" className="btn-primary btn-lg px-8">Start Protecting Devices</Link>
            <Link href="/login" className="btn-secondary btn-lg px-8">Sign In</Link>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-left">
            <div className="card card-pad"><h3 className="font-semibold mb-2">Offline First</h3><p className="text-sm text-muted-foreground">GPS logs locally when offline. Queue syncs automatically when connection restores. No data loss.</p></div>
            <div className="card card-pad"><h3 className="font-semibold mb-2">Platform Honest</h3><p className="text-sm text-muted-foreground">Never fakes GPS, commands, hotspot, camera, or reset protection. Shows UNSUPPORTED when OS does not allow.</p></div>
            <div className="card card-pad"><h3 className="font-semibold mb-2">Security First</h3><p className="text-sm text-muted-foreground">End-to-end encryption, RLS policies, audit logs, rate limiting. Anti-stalking by design.</p></div>
          </div>
          <div className="mt-12 grid grid-cols-2 md:grid-cols-4 gap-4 text-left">
            {[
              {t:'Live Tracking',d:'Realtime GPS when online'},
              {t:'Offline Queue',d:'Encrypted local storage'},
              {t:'Finder QR',d:'Anyone can scan to help'},
              {t:'Rescue Link',d:'Consent-based connectivity'}
            ].map(c=>(
              <div key={c.t} className="rounded-xl border bg-surface p-4">
                <p className="font-medium text-sm">{c.t}</p><p className="text-xs text-muted-foreground mt-1">{c.d}</p>
              </div>
            ))}
          </div>
          <div className="mt-10 p-4 rounded-xl border bg-amber-50 dark:bg-amber-950/20 text-left">
            <p className="text-sm font-medium text-amber-900 dark:text-amber-200">Honest Limitations</p>
            <p className="text-xs text-amber-800/80 dark:text-amber-200/70 mt-1">RETRACE depends on real OS capabilities. If device is powered off, has no connectivity, or OS blocks background work, we show last known location, offline queue, and finder mechanisms — we never fake a result.</p>
          </div>
        </div>
      </section>
    </main>
  );
}
