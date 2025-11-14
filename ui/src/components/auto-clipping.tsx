/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/components/auto-clipping.tsx
  =====================
  Description:
    Auto Clipping component for the UI
  ---
  Exports & Exported Components:
    - AutoClipping : The main component for the auto clipping UI
  ---
  Globals:
    None
*/

import { fetchNui, useNuiEvent } from '@tsfx/hooks';
import clsx from 'clsx';
import type React from 'react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useApiStatus } from '@/hooks/use-api-status';
import { Download } from './download';
import { Event, type EventData } from './event';
import { ScrollArea } from './ui/scroll-area';
import { Switch } from './ui/switch';

export const AutoClipping: React.FC = () => {
    const [events, setEvents] = useState<EventData[]>([]);
    const [enabled, setEnabled] = useState<boolean>(false);
    const { isAvailable } = useApiStatus();
    const { t } = useTranslation();

    const updateEnabled = (toggle: boolean): void => {
        setEnabled(toggle);
        fetchNui('ac:toggle', { payload: toggle });
    };

    useNuiEvent<boolean>('ac:enable', {
        handler: (enabled) => {
            setEnabled(enabled);
        },
    });

    useNuiEvent<EventData>('ac:event:register', {
        handler: (event) => {
            setEvents((prevEvents) => [...prevEvents, event]);
        },
    });

    return (
        <div className='w-full grow flex flex-col gap-2 font-medium'>
            {!isAvailable && <Download />}

            <div className='w-full h-6 flex items-center justify-between relative'>
                {!isAvailable && (
                    <div
                        className='size-full absolute inset-0 z-50'
                        style={{ backdropFilter: 'blur(1.25px)' }}
                    />
                )}

                <h4 className='font-medium'>{t('auto_clipping.title')}</h4>

                <div className='flex items-center gap-1.5'>
                    <span className='text-foreground-700 text-xs font-normal'>
                        {enabled ? t('auto_clipping.enabled') : t('auto_clipping.disabled')}
                    </span>

                    <Switch checked={enabled} onCheckedChange={updateEnabled} />
                </div>
            </div>

            <div
                className={clsx(
                    'w-full grow relative',
                    !enabled && 'opacity-40 pointer-events-none',
                )}
                style={{ containerType: 'size' }}
            >
                {!isAvailable && (
                    <div
                        className='size-full absolute inset-0 z-50'
                        style={{ backdropFilter: 'blur(1.25px)' }}
                    />
                )}

                <ScrollArea style={{ height: '100cqh' }}>
                    <div className='size-full flex flex-col gap-2'>
                        {events.map((event) => (
                            <Event key={event.id} event={event} />
                        ))}
                    </div>
                </ScrollArea>
            </div>
        </div>
    );
};
