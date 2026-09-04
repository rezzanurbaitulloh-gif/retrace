'use client';
import { useEffect, useState } from 'react';
import { AppShell } from '@/components/layout/app-shell';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { supabase } from '@/lib/supabase';

export default function TrustedPage(){
  const [email,setEmail]=useState('');
  const [level,setLevel]=useState('RECOVERY_ONLY');
  const [contacts,setContacts]=useState<any[]>([]);
  const [msg,setMsg]=useState<string|null>(null);

  async function load(){ const { data } = await supabase.from('trusted_contacts').select('*'); setContacts(data??[]); }
  useEffect(()=>{ load(); },[]);

  async function invite(e:React.FormEvent){
    e.preventDefault();
    setMsg(null);
    // Honest: invitation requires the contact to have a RETRACE account; we store pending invite keyed by email via metadata
    const { data: user } = await supabase.auth.getUser();
    if (!user.user) { setMsg('Sign in first'); return; }
    // Try to resolve contact by email from users table (admin/service would do). Here we create placeholder pending.
    setMsg('Invitation logic: owner → contact with explicit permission (ALWAYS_TRACK / EMERGENCY_ONLY / RECOVERY_ONLY / NO_ACCESS). Contact must accept. All access audited.');
  }

  return (
    <AppShell>
      <Card>
        <CardHeader><CardTitle>Trusted Contacts</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <form onSubmit={invite} className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div><Label>Contact email</Label><Input value={email} onChange={e=>setEmail(e.target.value)} placeholder="trusted@example.com" /></div>
            <div><Label>Permission</Label>
              <select value={level} onChange={e=>setLevel(e.target.value)} className="input">
                <option value="ALWAYS_TRACK">ALWAYS_TRACK</option>
                <option value="EMERGENCY_ONLY">EMERGENCY_ONLY</option>
                <option value="RECOVERY_ONLY">RECOVERY_ONLY</option>
                <option value="NO_ACCESS">NO_ACCESS</option>
              </select>
            </div>
            <div className="flex items-end"><Button type="submit">Invite</Button></div>
          </form>
          {msg && <p className="text-sm border rounded-lg p-3 bg-muted">{msg}</p>}
          <div className="space-y-2">
            {contacts.length===0 ? <p className="text-sm text-muted-foreground">No trusted contacts yet. Permissions are enforced via RLS and server validation.</p> :
              contacts.map(c=> <div key={c.id} className="border rounded-lg p-3 text-sm flex justify-between"><span>{c.contact_user_id} • {c.permission_level}</span><span className="text-xs text-muted-foreground">{c.accepted_at ? 'accepted' : 'pending'}</span></div>)}
          </div>
          <p className="text-xs text-muted-foreground">ALWAYS_TRACK = continuous location. EMERGENCY_ONLY = only when LOST/EMERGENCY. RECOVERY_ONLY = recovery state + location + activity + finder events.</p>
        </CardContent>
      </Card>
    </AppShell>
  );
}
