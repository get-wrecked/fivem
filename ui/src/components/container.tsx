/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/components/container.tsx
  =====================
  Description:
    The container component for the UI
  ---
  Exports & Exported Components:
    - Container : The container component
  ---
  Globals:
    None
*/

import { useNuiVisibility } from '@tsfx/hooks';
import type React from 'react';
import type { PropsWithChildren } from 'react';
import { cn } from '@/lib/utils';
import logo from '../assets/logo.svg';
import { useApiStatus } from '@/hooks/use-api-status';
import { useWebSocketStatus } from '@/hooks/use-websocket-status';
import { Tooltip, TooltipTrigger, TooltipContent } from '@/components/ui/tooltip';
import { Camera, CameraOff, Wifi, WifiOff } from 'lucide-react';

const Header: React.FC = () => {
    const { setVisible } = useNuiVisibility();
    const { isAvailable } = useApiStatus();
    const { isConnected } = useWebSocketStatus();

    return (
        <div className='w-full h-14 bg-second-layer flex items-center justify-between'>
            <span className='grow px-6 py-4'>
                <img src={logo} alt='Medal Logo' className='h-6' />
            </span>

            <div className='flex items-center gap-1 pr-2'>
                {/*//=-- Autoclipping API availability indicator */}
                <Tooltip>
                    <TooltipTrigger asChild>
                        <span
                            className='size-14 flex items-center justify-center hover:bg-accent-secondary rounded-md cursor-default'
                            aria-label={`Autoclipping API: ${isAvailable ? 'Available' : 'Unavailable'}`}
                            role='img'
                        >
                            {isAvailable ? (
                                <Camera size={16} className='text-green-500' />
                            ) : (
                                <CameraOff size={16} className='text-foreground-300' />
                            )}
                        </span>
                    </TooltipTrigger>
                    <TooltipContent sideOffset={6}>
                        Autoclipping API: {isAvailable ? 'Available' : 'Unavailable'}
                    </TooltipContent>
                </Tooltip>

                {/*//=-- WebSocket connection indicator */}
                <Tooltip>
                    <TooltipTrigger asChild>
                        <span
                            className='size-14 flex items-center justify-center hover:bg-accent-secondary rounded-md cursor-default'
                            aria-label={`WebSocket: ${isConnected ? 'Connected' : 'Disconnected'}`}
                            role='img'
                        >
                            {isConnected ? (
                                <Wifi size={16} className='text-green-500' />
                            ) : (
                                <WifiOff size={16} className='text-foreground-300' />
                            )}
                        </span>
                    </TooltipTrigger>
                    <TooltipContent sideOffset={6}>WebSocket: {isConnected ? 'Connected' : 'Disconnected'}</TooltipContent>
                </Tooltip>

                {/*//=-- Close button */}
                <button
                    type='button'
                    onClick={() => setVisible(false)}
                    className='group size-14 flex items-center justify-center hover:bg-accent-secondary cursor-pointer'
                >
                    <svg
                        width='16'
                        height='16'
                        viewBox='0 0 16 16'
                        fill='none'
                        xmlns='http://www.w3.org/2000/svg'
                        role='img'
                        aria-label='close'
                        className='fill-foreground-300 group-hover:fill-foreground-0 transition-colors duration-200 ease-in-out'
                    >
                        <path d='M13.3158 0.460493C13.9298 -0.153378 14.9252 -0.153495 15.5392 0.460493C16.153 1.07449 16.153 2.06991 15.5392 2.68392L2.68387 15.5392C2.06987 16.153 1.07445 16.153 0.460447 15.5392C-0.153541 14.9252 -0.153423 13.9299 0.460447 13.3158L13.3158 0.460493Z' />
                        <path d='M0.460535 0.460535C1.07458 -0.153512 2.06991 -0.153512 2.68396 0.460535L15.5393 13.3158L15.6478 13.4346C16.1513 14.0522 16.1149 14.9637 15.5393 15.5393C14.9637 16.1149 14.0522 16.1513 13.4346 15.6478L13.3158 15.5393L0.460535 2.68396C-0.153512 2.06991 -0.153512 1.07458 0.460535 0.460535Z' />
                    </svg>

                    <span className='sr-only'>Close</span>
                </button>
            </div>
        </div>
    );
};

export const Container: React.FC<PropsWithChildren> = ({ children }) => {
    const { visible } = useNuiVisibility();

    return (
        <div
            data-state={visible ? 'show' : 'hide'}
            className={cn(
                'absolute right-0 top-1/2 mr-8 -translate-y-1/2 w-[360px] h-[420px] bg-third-layer rounded-lg overflow-hidden flex flex-col',
                'data-[state=show]:animate-in data-[state=hide]:animate-out slide-in-from-right fade-in slide-out-to-right fade-out duration-200 ease-in-out',
            )}
        >
            <Header />

            <div className='w-full grow py-4 px-6 flex flex-col gap-4 text-foreground-0'>
                {children}
            </div>
        </div>
    );
};
