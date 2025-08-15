import type React from 'react';
import { useState } from 'react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';

export const ClipLength: React.FC = () => {
    const [length, setLength] = useState<string>('30');

    return (
        <div className='w-full h-9 flex items-center justify-between font-medium'>
            <span>Clip Length</span>

            <Select value={length} onValueChange={setLength}>
                <SelectTrigger className='w-32'>
                    <SelectValue />
                </SelectTrigger>
                <SelectContent>
                    <SelectItem value='15'>15 seconds</SelectItem>
                    <SelectItem value='30'>30 seconds</SelectItem>
                    <SelectItem value='1'>1 minute</SelectItem>
                    <SelectItem value='2'>2 minutes</SelectItem>
                    <SelectItem value='3'>3 minutes</SelectItem>
                    <SelectItem value='5'>5 minutes</SelectItem>
                </SelectContent>
            </Select>
        </div>
    );
};
