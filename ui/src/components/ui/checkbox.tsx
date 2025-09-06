/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/components/ui/checkbox.tsx
  =====================
  Description:
    A checkbox component for the UI
  ---
  Exports & Exported Components:
    - Checkbox : The checkbox component
  ---
  Globals:
    None
*/

import * as CheckboxPrimitive from '@radix-ui/react-checkbox';
import type * as React from 'react';

import { cn } from '@/lib/utils';

function Checkbox({ className, ...props }: React.ComponentProps<typeof CheckboxPrimitive.Root>) {
    return (
        <CheckboxPrimitive.Root
            data-slot='checkbox'
            className={cn(
                'peer border-neutral-800 data-[state=checked]:bg-foreground-0 data-[state=checked]:text-[#1f1f20] data-[state=checked]:border-foreground-0 focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 aria-invalid:border-destructive size-5 shrink-0 rounded-[4px] border shadow-xs transition-shadow outline-none focus-visible:ring-[3px] disabled:cursor-not-allowed disabled:opacity-50',
                className,
            )}
            {...props}
        >
            <CheckboxPrimitive.Indicator
                data-slot='checkbox-indicator'
                className='flex items-center justify-center text-current transition-none'
            >
                <svg
                    width='14'
                    height='10'
                    viewBox='0 0 14 10'
                    fill='none'
                    xmlns='http://www.w3.org/2000/svg'
                    role='img'
                    aria-label='checked'
                >
                    <path
                        fill-rule='evenodd'
                        clipRule='evenodd'
                        d='M7.15021 8.98238C6.2923 9.89499 4.85751 9.89499 3.9996 8.98238L0.828509 5.60911C0.330225 5.07906 0.34946 4.2392 0.871471 3.73324C1.39348 3.22728 2.22059 3.24681 2.71888 3.77687L5.5749 6.81499L11.2818 0.744185C11.7801 0.214132 12.6072 0.194601 13.1292 0.700561C13.6513 1.20652 13.6705 2.04637 13.1722 2.57643L7.15021 8.98238Z'
                        fill='#1F1F20'
                    />
                </svg>
            </CheckboxPrimitive.Indicator>
        </CheckboxPrimitive.Root>
    );
}

export { Checkbox };
