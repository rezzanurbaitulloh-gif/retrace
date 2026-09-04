import * as React from 'react'; import { cn } from '@/lib/utils';
type Variant='primary'|'secondary'|'danger'|'ghost'; type Size='sm'|'md'|'lg';
const variantClass:Record<Variant,string>={ primary:'btn-primary', secondary:'btn-secondary', danger:'btn-danger', ghost:'btn-ghost' };
const sizeClass:Record<Size,string>={ sm:'btn-sm', md:'', lg:'btn-lg' };
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement>{ variant?:Variant; size?:Size; loading?:boolean }
export const Button=React.forwardRef<HTMLButtonElement,ButtonProps>(({className,variant='primary',size='md',loading,children,disabled,...props},ref)=>(
  <button ref={ref} className={cn(variantClass[variant],sizeClass[size],className)} disabled={disabled||loading} aria-busy={loading||undefined} {...props}>
    {loading && <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" aria-hidden="true" />}
    {children}
  </button>
)); Button.displayName='Button';
