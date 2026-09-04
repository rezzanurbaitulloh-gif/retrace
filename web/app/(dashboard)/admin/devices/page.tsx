import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StateView } from '@/components/ui/state';
export default function AdminDevicesPage(){
  return (
    <AppShell>
      <div className="space-y-4">
        <h1 className="text-xl font-bold">Admin — Devices</h1>
        <Card><CardHeader><CardTitle>Inspect</CardTitle></CardHeader>
          <CardContent><StateView state="empty" title="Select a device" description="Admin can: inspect device, state, location metadata, activity, recovery, disable/enable device, revoke sessions (PRD 71). State includes ONLINE/OFFLINE/LOST etc." /></CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
