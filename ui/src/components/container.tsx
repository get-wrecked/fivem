import { useNuiVisibility } from '@tsfx/hooks';
import { X } from 'lucide-react';
import type React from 'react';
import type { PropsWithChildren } from 'react';
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
    return (
        <div className='absolute right-0 top-1/2 mr-8 -translate-y-1/2 w-[360px] h-[420px] bg-third-layer rounded-lg overflow-hidden flex flex-col'>
            <Header />

            <div className='w-full grow py-4 px-6 flex flex-col gap-4 text-foreground-0'>
                {children}
            </div>
        </div>
    );
};
