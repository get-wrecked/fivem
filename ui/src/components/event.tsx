/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/components/event.tsx
  =====================
  Description:
    Event component for the auto clipping UI
  ---
  Exports & Exported Components:
    - Event: Main event component
  ---
  Globals:
    None
*/

import type { CheckedState } from '@radix-ui/react-checkbox';
import { fetchNui, useNuiEvent } from '@tsfx/hooks';
import type React from 'react';
import { useEffect, useState } from 'react';
import { useClipLength } from '@/hooks/use-clip-length';
import { triggerClip } from '@/lib/medal';
import { Checkbox } from './ui/checkbox';
import { Tooltip, TooltipContent, TooltipTrigger } from './ui/tooltip';

export interface EventData {
    id: string;
    title: string;
    desc?: string;
}

export const Event: React.FC<{ event: EventData }> = ({ event }) => {
    const { length } = useClipLength();
    const [enabled, setEnabled] = useState<boolean>(true);

    const updateEnabled = (checked: CheckedState): void => {
        const toggle = checked === 'indeterminate' ? false : checked;

        setEnabled(toggle);
        fetchNui('ac:event:toggle', { payload: { toggle, id: event.id } });
    };

    useNuiEvent<string[]>(`ac:clip:${event.id}`, {
        handler: (tags) => {
            if (enabled) {
                triggerClip({
                    eventId: event.id,
                    eventName: event.title,
                    triggerActions: ['SaveClip'],
                    clipOptions: {
                        duration: Number(length) ?? 30,
                        captureDelayMs: 1000,
                    },
                });
            }
        },
    });

    useEffect(() => {
        fetchNui<boolean>('ac:event:enable', { payload: event.id }).then((result) => {
            setEnabled(result);
        });
    }, [event.id]);

    return (
        <div className='w-full h-7 p-1 flex items-center gap-1.5'>
            <Checkbox checked={enabled} onCheckedChange={updateEnabled} />

            <p className='text-base'>{event.title}</p>

            {event.desc && (
                <Tooltip>
                    <TooltipTrigger>
                        <svg
                            width='20'
                            height='20'
                            viewBox='0 0 20 20'
                            fill='none'
                            xmlns='http://www.w3.org/2000/svg'
                            className='size-3.5'
                            role='img'
                            aria-label='info'
                        >
                            <path
                                d='M10 0C15.5228 0 20 4.47715 20 10C20 15.5228 15.5228 20 10 20C4.47715 20 0 15.5228 0 10C0 4.47715 4.47715 0 10 0ZM8.33301 8.88867V16.667H11.667V8.88867H8.33301ZM8.33301 3.33301V6.66699H11.667V3.33301H8.33301Z'
                                fill='#8e8e8e'
                            />
                        </svg>
                    </TooltipTrigger>

                    <TooltipContent>{event.desc}</TooltipContent>
                </Tooltip>
            )}
        </div>
    );
};
