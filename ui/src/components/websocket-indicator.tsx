/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/components/websocket-indicator.tsx
  =====================
  Description:
    WebSocket connection status indicator with tooltip
  ---
  Exports & Exported Components:
    - WebSocketIndicator: The WebSocket status indicator component
  ---
  Globals:
    None
*/

import { Wifi, WifiOff } from 'lucide-react';
import type React from 'react';
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip';
import { useWebSocketStatus } from '@/hooks/use-websocket-status';

////=-- Standalone indicator for WebSocket connectivity state
export const WebSocketIndicator: React.FC = () => {
    const { isConnected } = useWebSocketStatus();

    return (
        <Tooltip>
            <TooltipTrigger asChild>
                <span
                    className='size-8 flex items-center justify-center cursor-default p-2'
                    aria-label={`WebSocket: ${isConnected ? 'Connected' : 'Disconnected'}`}
                    role='img'
                >
                    {isConnected ? (
                        <Wifi className='text-success-400' />
                    ) : (
                        <WifiOff className='text-foreground-300' />
                    )}
                </span>
            </TooltipTrigger>

            <TooltipContent sideOffset={6}>
                WebSocket: {isConnected ? 'Connected' : 'Disconnected'}
            </TooltipContent>
        </Tooltip>
    );
};
