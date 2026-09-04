import * as React from 'react'; import { cn } from '@/lib/utils';
export function Select({className,children,...props}:React.SelectHTMLAttributes<HTMLSelectElement>){ return <select className={cn('input',className)} {...props}>{children}</select>; }
