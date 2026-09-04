import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
export function ContactInfoSafe({displayName="Reja", preferred="Signal", message="Please contact me, reward available"}:{displayName?:string; preferred?:string; message?:string}){
  return (
    <Card>
      <CardHeader><CardTitle>Safe Contact (PRD 14)</CardTitle></CardHeader>
      <CardContent className="space-y-2 text-sm">
        <p><span className="font-medium">Display Name:</span> {displayName}</p>
        <p><span className="font-medium">Preferred contact:</span> {preferred}</p>
        <p><span className="font-medium">Recovery message:</span> {message}</p>
        <p className="text-xs text-muted-foreground">Never shows: password, Recovery PIN, private address, sensitive account data.</p>
      </CardContent>
    </Card>
  );
}
