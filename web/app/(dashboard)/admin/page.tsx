'use client';
import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';

export default function AdminPage(){
  const [isAdmin,setIsAdmin]=useState<boolean|null>(null);
  useEffect(()=>{ (async()=>{
    const { data:{user} } = await supabase.auth.getUser();
    if (!user) { setIsAdmin(false); return; }
    const { data } = await supabase.from('admin_users').select('id').eq('user_id', user.id).limit(1);
    setIsAdmin(!!data && data.length>0);
  })(); },[]);
  if (isAdmin===null) return <AppShell><div className="h-64 bg-muted animate-pulse rounded-xl" /></AppShell>;
  if (!isAdmin) return <AppShell><Card><CardContent className="p-8 text-center"><p className="font-medium">Admin access required</p><p className="text-sm text-muted-foreground">God mode requires admin role. Every action is audited: Admin → Action → Target → Reason → Timestamp → Result → Audit Log.</p></CardContent></Card></AppShell>;
  return (
    <AppShell>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card><CardHeader><CardTitle>Overview</CardTitle></CardHeader><CardContent className="space-y-2 text-sm"><div className="flex justify-between"><span>Users</span><Badge variant="outline">—</Badge></div><div className="flex justify-between"><span>Devices</span><Badge variant="outline">—</Badge></div><div className="flex justify-between"><span>Active cases</span><Badge variant="outline">—</Badge></div></CardContent></Card>
        <Card><CardHeader><CardTitle>Live Map</CardTitle></CardHeader><CardContent><p className="text-sm text-muted-foreground">Active recovery cases on map. Real-time via Supabase Realtime.</p></CardContent></Card>
        <Card><CardHeader><CardTitle>Audit Logs</CardTitle></CardHeader><CardContent><p className="text-sm text-muted-foreground">All admin actions are immutable and require a reason. No plaintext passwords, PINs, or keys are ever exposed.</p></CardContent></Card>
      </div>
    </AppShell>
  );
}
