'use client';
import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { Input, Label } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';

export default function LoginPage(){
  const router=useRouter();
  const [email,setEmail]=useState('');
  const [password,setPassword]=useState('');
  const [recoveryPin,setRecoveryPin]=useState('');
  const [loading,setLoading]=useState(false);
  const [error,setError]=useState<string|null>(null);
  const [showRecovery,setShowRecovery]=useState(false);

  async function onLogin(e:React.FormEvent){
    e.preventDefault();
    setError(null); setLoading(true);
    try{
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      router.push('/dashboard');
    } catch(err:any){ setError(err.message ?? 'Login failed'); }
    finally{ setLoading(false); }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-background">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Sign in to RETRACE</CardTitle>
          <CardDescription>Recovery-first. Offline-first. Platform-honest.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={onLogin} className="space-y-4">
            <div>
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="you@example.com" autoComplete="email" />
            </div>
            <div>
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" required value={password} onChange={e=>setPassword(e.target.value)} autoComplete="current-password" />
            </div>
            {showRecovery && (
              <div>
                <Label htmlFor="pin">Recovery PIN (for sensitive recovery)</Label>
                <Input id="pin" type="password" inputMode="numeric" value={recoveryPin} onChange={e=>setRecoveryPin(e.target.value)} placeholder="6-digit PIN" />
                <p className="text-xs text-muted-foreground mt-1">Recovery PIN never equals device lock screen PIN. Required for recovery actions.</p>
              </div>
            )}
            {error && <p role="alert" className="text-sm text-destructive bg-destructive/10 border border-destructive/20 rounded-lg px-3 py-2">{error}</p>}
            <Button type="submit" loading={loading} className="w-full">Sign In</Button>
            <div className="flex items-center justify-between text-sm">
              <button type="button" onClick={()=>setShowRecovery(v=>!v)} className="text-muted-foreground hover:text-foreground underline underline-offset-4">
                {showRecovery ? 'Hide recovery' : 'Use recovery credential'}
              </button>
              <Link href="/forgot-password" className="text-primary hover:underline">Forgot password?</Link>
            </div>
            <p className="text-sm text-center text-muted-foreground">No account? <Link href="/signup" className="text-primary hover:underline font-medium">Sign up</Link></p>
            <p className="text-xs text-muted-foreground text-center">Borrowed device? You get a restricted, short-lived, recovery-only session with rate limiting and device challenge.</p>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
