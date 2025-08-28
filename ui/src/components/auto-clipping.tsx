import { useNuiEvent } from '@tsfx/hooks';
import type React from 'react';
import { useState } from 'react';
import { Event, type EventData } from './event';
import { ScrollArea } from './ui/scroll-area';
import { Switch } from './ui/switch';

export const AutoClipping: React.FC = () => {
    const [events, setEvents] = useState<EventData[]>([]);
    const [enabled, setEnabled] = useState<boolean>(false);

    useNuiEvent<EventData>('ac:event:register', {
        handler: (event) => {
            const currentEvents = events;
            currentEvents.push(event);
            setEvents(currentEvents);
        },
    });

    return (
        <div className='w-full grow flex flex-col gap-2 font-medium'>
            <div className='w-full h-6 flex items-center justify-between'>
                <h4 className='font-medium'>Auto Clipping</h4>

                <div className='flex items-center gap-1.5'>
                    <span className='text-foreground-700 text-xs font-normal'>
                        {enabled ? 'ON' : 'OFF'}
                    </span>

                    <Switch checked={enabled} onCheckedChange={setEnabled} />
                </div>
            </div>

            <div className='w-full grow' style={{ containerType: 'size' }}>
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
