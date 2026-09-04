'use client';
import { useState } from 'react';
import Link from 'next/link';
import { Input, Label } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
export default function ForgotPasswordPage(){
  const [email,setEmail]=useState(''); const [sent,setSent]=useState(false);
  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-background">
      <Card className="w-full max-w-md">
        <CardHeader><CardTitle>Reset password</CardTitle><CardDescription>We send a recovery link. Unknown-device logins get restricted sessions.</CardDescription></CardHeader>
        <CardContent>
          {!sent ? (
            <form onSubmit={e=>{e.preventDefault(); setSent(true);}} className="space-y-4">
              <div><Label htmlFor="email">Email</Label><Input id="email" type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="you@example.com" /></div>
              <Button type="submit" className="w-full">Send reset link</Button>
              <p className="text-sm text-center text-muted-foreground"><Link href="/login" className="text-primary hover:underline">Back to sign in</Link></p>
            </form>
          ) : (
            <div className="space-y-3">
              <p className="text-sm">If an account exists for <span className="font-medium">{email}</span>, you will receive a reset link.</p>
              <p className="text-xs text-muted-foreground">Rate limited: 5/15min. Recovery supports PIN + device challenge.</p>
              <Link href="/login" className="btn-secondary w-full justify-center">Back to sign in</Link>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
