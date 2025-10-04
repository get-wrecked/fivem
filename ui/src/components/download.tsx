import { fetchNui } from '@tsfx/hooks';
import type React from 'react';
import { Button } from './ui/button';

export const Download: React.FC = () => {
    const openLink = () => {
        fetchNui('');
    };

    return (
        <div className='w-full h-28 bg-second-layer border border-foreground-700 mb-3 rounded-lg flex items-center justify-center flex-col gap-1'>
            <span className='font-medium text-sm'>Enable Auto Clipping with Medal</span>
            <span className='text-foreground-300 font-normal text-xs'>
                Automatically clip top events for this server
            </span>

            <Button onClick={openLink} size='sm' className='mt-2.5'>
                <svg
                    width='24'
                    height='24'
                    viewBox='0 0 24 24'
                    fill='none'
                    xmlns='http://www.w3.org/2000/svg'
                    className='fill-foreground-950 size-4'
                    role='img'
                    aria-label='Download'
                >
                    <path d='M18.8889 13.1111H18.6667L16.4444 15.2222V15.3333H18.8889C19.3333 15.3333 19.7778 15.6667 19.7778 16.2222V18.8889C19.7778 19.3333 19.4444 19.7778 18.8889 19.7778H5.11112C4.55556 19.7778 4.22222 19.4444 4.22222 18.8889V16.2222C4.22222 15.7778 4.55556 15.3333 5.11112 15.3333H7.44444L5.33334 13.1111H5.11112C3.33333 13.1111 2 14.5556 2 16.2222V18.8889C2 20.6667 3.33333 22 5.11112 22H18.8889C20.5556 22 22 20.6667 22 18.8889V16.2222C22 14.5556 20.5556 13.1111 18.8889 13.1111Z' />
                    <path d='M7.2218 9.77778H10.444V2H13.7773V9.77778H16.7773C17.444 9.77778 17.7773 10.6667 17.3329 11.1111L12.3329 16.2222C11.9996 16.5556 11.5551 16.5556 11.2218 16.2222L6.66624 11C6.2218 10.5556 6.55512 9.77778 7.2218 9.77778Z' />
                </svg>
                <span className='text-sm font-medium'>Download</span>
            </Button>
        </div>
    );
};
