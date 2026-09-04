import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StateView } from '@/components/ui/state';
export default function AdminUsersPage(){
  return (
    <AppShell>
      <div className="space-y-4">
        <h1 className="text-xl font-bold">Admin — Users</h1>
        <Card><CardHeader><CardTitle>Search & Inspect</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            <input placeholder="Search by email, name, phone" className="input" />
            <StateView state="empty" title="No search yet" description="Admin can: search user, view profile, inspect devices, suspend/restore account, revoke sessions, inspect recovery case, assist recovery (PRD 70). Every action requires reason and is audited." />
          </CardContent>
        </Card>
        <Card><CardHeader><CardTitle>Privileged actions — no plaintext secrets</CardTitle></CardHeader>
          <CardContent><p className="text-sm text-muted-foreground">Admin never sees passwords, Recovery PIN, or crypto secrets. Works via privileged server actions (PRD 74).</p></CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
