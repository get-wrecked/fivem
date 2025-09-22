/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/components/api-indicator.tsx
  =====================
  Description:
    Autoclipping API availability indicator with tooltip
  ---
  Exports & Exported Components:
    - ApiIndicator: The Autoclipping API status indicator component
  ---
  Globals:
    None
*/

import { Camera, CameraOff } from 'lucide-react';
import type React from 'react';
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip';
import { useApiStatus } from '@/hooks/use-api-status';

////=-- Standalone indicator for Autoclipping API availability
export const ApiIndicator: React.FC = () => {
    const { isAvailable } = useApiStatus();

    return (
        <Tooltip>
            <TooltipTrigger asChild>
                <span
                    className='size-8 flex items-center justify-center cursor-default p-2'
                    aria-label={`Autoclipping API: ${isAvailable ? 'Available' : 'Unavailable'}`}
                    role='img'
                >
                    {isAvailable ? (
                        <Camera className='text-success-400' />
                    ) : (
                        <CameraOff className='text-foreground-300' />
                    )}
                </span>
            </TooltipTrigger>
            <TooltipContent sideOffset={6}>
                Autoclipping API: {isAvailable ? 'Available' : 'Unavailable'}
            </TooltipContent>
        </Tooltip>
    );
};
