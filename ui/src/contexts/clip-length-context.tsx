import { createContext } from 'react';

export interface ClipLengthContextValue {
    length: string;
    setLength: (length: string) => void;
}

export const ClipLengthContext = createContext<ClipLengthContextValue>({
    length: '30',
    setLength: () => {
        console.error('Failed to set clip length. The context has not been initialized.');
    },
});
