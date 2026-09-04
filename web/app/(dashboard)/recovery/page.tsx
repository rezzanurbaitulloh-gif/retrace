import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import Link from 'next/link';

export default function RecoveryPage(){
  return (
    <AppShell>
      <Card>
        <CardHeader><CardTitle>Recovery</CardTitle></CardHeader>
        <CardContent className="space-y-3 text-sm">
          <p>Single-device owner recovery (lost your only device): borrow a friend phone → open RETRACE → Recovery login with account identifier + recovery credential + additional verification → recovery dashboard.</p>
          <div className="rounded-lg border p-3 bg-muted">
            <p className="font-medium">Quick Recovery (low friction, still secure)</p>
            <p className="text-xs text-muted-foreground">Rate limit + device challenge + short-lived restricted session + optional trusted contact confirmation.</p>
          </div>
          <Link href="/devices" className="btn-primary btn-sm">Go to Devices → Mark as Lost</Link>
          <p className="text-xs text-muted-foreground">Unknown device = restricted, recovery-only, short session, additional verification. Never expose passwords, Recovery PIN, or private address.</p>
        </CardContent>
      </Card>
    </AppShell>
  );
}
