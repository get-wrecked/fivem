/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/components/ui/switch.tsx
  =====================
  Description:
    The switch component for the UI
  ---
  Exports & Exported Components:
    - Switch : The switch component
  ---
  Globals:
    None
*/

import * as SwitchPrimitive from '@radix-ui/react-switch';
import type * as React from 'react';

import { cn } from '@/lib/utils';

function Switch({ className, ...props }: React.ComponentProps<typeof SwitchPrimitive.Root>) {
    return (
        <SwitchPrimitive.Root
            data-slot='switch'
            className={cn(
                'peer data-[state=checked]:bg-foreground-0 data-[state=unchecked]:bg-neutral-800 focus-visible:border-ring focus-visible:ring-foreground-0/50 inline-flex h-6 w-11 shrink-0 items-center rounded-full border border-transparent shadow-xs transition-all outline-none focus-visible:ring-[3px] disabled:cursor-not-allowed disabled:opacity-50',
                className,
            )}
            {...props}
        >
            <SwitchPrimitive.Thumb
                data-slot='switch-thumb'
                className={cn(
                    'bg-second-layer pointer-events-none block size-5 rounded-full ring-0 transition-transform data-[state=checked]:translate-x-5 data-[state=unchecked]:translate-x-0.5',
                )}
            />
        </SwitchPrimitive.Root>
    );
}

export { Switch };
