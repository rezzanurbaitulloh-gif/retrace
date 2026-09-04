import * as React from 'react'; import { cn } from '@/lib/utils';
export function Badge({className,variant='default',...props}:React.HTMLAttributes<HTMLSpanElement> & {variant?:'default'|'success'|'warning'|'danger'|'outline'}){
  const v={ default:'bg-muted text-foreground', success:'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300', warning:'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300', danger:'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300', outline:'border border-border text-foreground' }[variant];
  return <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',v,className)} {...props} />;
}
export function StatusBadge({status}:{status:string}){
  const map:Record<string,string>={ ACTIVE:'success', ONLINE:'success', OFFLINE:'outline', LOST:'danger', RECOVERING:'warning', RECOVERED:'success', PENDING:'outline', DISABLED:'outline' };
  return <Badge variant={(map[status] as any)||'outline'}>{status}</Badge>;
}
