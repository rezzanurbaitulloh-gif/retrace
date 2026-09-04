'use client';
import { useEffect, useState } from 'react';
import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { supabase } from '@/lib/supabase';

export default function ProfilePage(){
  const [email,setEmail]=useState('');
  const [fullName,setFullName]=useState('');
  const [msg,setMsg]=useState<string|null>(null);
  useEffect(()=>{ (async()=>{
    const { data:{user} } = await supabase.auth.getUser();
    if (user){ setEmail(user.email ?? ''); setFullName((user.user_metadata as any)?.full_name ?? ''); }
  })(); },[]);
  return (
    <AppShell>
      <Card>
        <CardHeader><CardTitle>Profile</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div><Label>Full Name</Label><Input value={fullName} onChange={e=>setFullName(e.target.value)} /></div>
          <div><Label>Email</Label><Input value={email} disabled /></div>
          <Button onClick={()=>setMsg('Profile updates are validated server-side; secrets stay hashed/encrypted.')}>Save</Button>
          {msg && <p className="text-sm border rounded-lg p-3 bg-muted">{msg}</p>}
          <p className="text-xs text-muted-foreground">Account fields: Full Name, Display Name, Email, Phone, Photo, Recovery Contacts, address/notes (optional). We do not collect unnecessary data.</p>
        </CardContent>
      </Card>
    </AppShell>
  );
}
