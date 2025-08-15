import type React from 'react';
import { ScrollArea } from './ui/scroll-area';
import { Switch } from './ui/switch';

export const AutoClipping: React.FC = () => {
    return (
        <div className='w-full grow flex flex-col gap-2'>
            <div className='w-full h-6 flex items-center justify-between'>
                <span>Auto Clipping</span>

                <div className='flex items-center gap-1.5'>
                    <span className='text-foreground-0/50 text-xs'>ON</span>
                    <Switch />
                </div>
            </div>

            <div className='w-full grow' style={{ containerType: 'size' }}>
                <ScrollArea style={{ height: '100cqh' }}></ScrollArea>
            </div>
        </div>
    );
};
