import type React from 'react';
import { Checkbox } from './ui/checkbox';
import { Tooltip, TooltipContent, TooltipTrigger } from './ui/tooltip';

export const Event: React.FC = () => {
    return (
        <div className='w-full h-7 p-1 flex items-center gap-1.5'>
            <Checkbox />

            <p className='text-base'>Test</p>

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
                <TooltipContent>Test</TooltipContent>
            </Tooltip>
        </div>
    );
};
