import { useNuiVisibility } from '@tsfx/hooks';
import { X } from 'lucide-react';
import type React from 'react';
import type { PropsWithChildren } from 'react';
import { cn } from '@/lib/utils';
import logo from '../assets/logo.svg';

const Header: React.FC = () => {
    const { setVisible } = useNuiVisibility();

    return (
        <div className='w-full h-14 bg-second-layer flex items-center justify-between'>
            <span className='grow px-6 py-4'>
                <img src={logo} alt='Medal Logo' className='h-6' />
            </span>

            <button
                type='button'
                onClick={() => setVisible(false)}
                className='size-14 flex items-center justify-center text-foreground-300 hover:bg-accent-secondary hover:text-foreground-0 cursor-pointer'
            >
                <X />
                <span className='sr-only'>Close</span>
            </button>
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
                'data-[state=show]:animate-in data-[state=hide]:animate-out slide-in-from-right slide-out-to-right duration-200 ease-in-out',
            )}
        >
            <Header />

            <div className='w-full grow py-4 px-6 flex flex-col gap-4 text-foreground-0'>
                {children}
            </div>
        </div>
    );
};
