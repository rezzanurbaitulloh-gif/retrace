import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
export default function AdminAuditPage(){
  return (
    <AppShell>
      <div className="space-y-4">
        <h1 className="text-xl font-bold">Admin — Audit Logs</h1>
        <Card><CardHeader><CardTitle>Every admin action is audited</CardTitle></CardHeader>
          <CardContent className="space-y-2 text-sm">
            <div className="rounded-lg border p-3 font-mono text-xs">
              Admin → Action → Target → Reason → Timestamp → Result → Audit Log (PRD 73)
            </div>
            <div className="overflow-auto rounded-lg border">
              <table className="w-full text-xs">
                <thead className="bg-muted"><tr><th className="p-2 text-left">audit_id</th><th className="p-2">admin_id</th><th className="p-2">action</th><th className="p-2">target</th><th className="p-2">reason</th><th className="p-2">timestamp</th><th className="p-2">result</th></tr></thead>
                <tbody><tr><td className="p-2" colSpan={7}>No logs yet — insert via admin_actions / audit_logs with RLS (PRD 75)</td></tr></tbody>
              </table>
            </div>
            <p className="text-xs text-muted-foreground">God mode is not unaudited. Immutable logs, admin never sees plaintext secrets.</p>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
