import { fetchNui } from '@tsfx/hooks';
import type React from 'react';
import { useState } from 'react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';

export const ClipLength: React.FC = () => {
    const [length, setLength] = useState<string>('30');

    const updateLength = (value: string): void => {
        setLength(value);
        fetchNui('ac:length', { payload: value });
    };

    return (
        <div className='w-full h-9 flex items-center justify-between font-normal'>
            <span className='font-medium'>Clip Length</span>

            <Select value={length} onValueChange={updateLength}>
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
