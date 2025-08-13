import type React from 'react';
import { ScrollArea } from './ui/scroll-area';

export const AutoClipping: React.FC = () => {
    return (
        <div className='w-full grow' style={{ containerType: 'size' }}>
            <ScrollArea style={{ height: '100cqh' }}></ScrollArea>
        </div>
    );
};
