import { useNuiEvent } from '@tsfx/hooks';
import type { PropsWithChildren } from 'react';
import { useState } from 'react';
import { ClipLengthContext, type ClipLengthContextValue } from '@/contexts/clip-length-context';

export interface ClipLengthProviderProps {
    context?: React.Context<ClipLengthContextValue>;
    initialLength?: string;
}

export const ClipLengthProvider: React.FC<PropsWithChildren<ClipLengthProviderProps>> = ({
    children,
    context = ClipLengthContext,
    initialLength = '30',
}) => {
    const [length, setLength] = useState<string>(initialLength);

    useNuiEvent<number>('ac:length', {
        handler: (length) => {
            setLength(length.toString());
        },
    });

    return <context.Provider value={{ length, setLength }}>{children}</context.Provider>;
};
