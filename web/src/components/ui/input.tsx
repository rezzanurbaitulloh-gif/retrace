import * as React from 'react'; import { cn } from '@/lib/utils';
export const Input=React.forwardRef<HTMLInputElement,React.InputHTMLAttributes<HTMLInputElement>>(({className,type,...props},ref)=><input type={type} className={cn('input',className)} ref={ref} {...props} />); Input.displayName='Input';
export const Label=React.forwardRef<HTMLLabelElement,React.LabelHTMLAttributes<HTMLLabelElement>>(({className,...props},ref)=><label ref={ref} className={cn('label',className)} {...props} />); Label.displayName='Label';
