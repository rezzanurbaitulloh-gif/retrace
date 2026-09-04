'use client';
import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { Input, Label } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';

export default function SignupPage(){
  const router=useRouter();
  const [fullName,setFullName]=useState('');
  const [email,setEmail]=useState('');
  const [password,setPassword]=useState('');
  const [recoveryPin,setRecoveryPin]=useState('');
  const [loading,setLoading]=useState(false);
  const [error,setError]=useState<string|null>(null);

  async function onSignup(e:React.FormEvent){
    e.preventDefault();
    setError(null);
    if (recoveryPin.length<6) { setError('Recovery PIN must be 6-10 digits and not equal to device lock PIN'); return; }
    setLoading(true);
    try{
      const { error } = await supabase.auth.signUp({ email, password, options:{ data:{ full_name: fullName } } });
      if (error) throw error;
      router.push('/login');
    } catch(err:any){ setError(err.message ?? 'Signup failed'); }
    finally{ setLoading(false); }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-background">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Create your RETRACE account</CardTitle>
          <CardDescription>Device recovery starts with a secure identity. We never store plaintext secrets.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSignup} className="space-y-4">
            <div>
              <Label htmlFor="name">Full Name</Label>
              <Input id="name" required value={fullName} onChange={e=>setFullName(e.target.value)} placeholder="Reja Nur" />
            </div>
            <div>
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="you@example.com" />
            </div>
            <div>
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" required value={password} onChange={e=>setPassword(e.target.value)} />
            </div>
            <div>
              <Label htmlFor="pin">Recovery PIN (6-10 digits)</Label>
              <Input id="pin" type="password" inputMode="numeric" required value={recoveryPin} onChange={e=>setRecoveryPin(e.target.value)} placeholder="— — — — — —" />
              <p className="text-xs text-muted-foreground mt-1">Hashed with Argon2id. Never reuse your device lock PIN.</p>
            </div>
            {error && <p role="alert" className="text-sm text-destructive bg-destructive/10 border rounded-lg px-3 py-2">{error}</p>}
            <Button type="submit" loading={loading} className="w-full">Create Account</Button>
            <p className="text-sm text-center text-muted-foreground">Already have an account? <Link href="/login" className="text-primary hover:underline font-medium">Sign in</Link></p>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
