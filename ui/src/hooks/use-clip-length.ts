import { useContext } from 'react';
import { ClipLengthContext, type ClipLengthContextValue } from '@/contexts/clip-length-context';

export const useClipLength = (): ClipLengthContextValue => {
    const context = useContext(ClipLengthContext);

    if (!context) {
        throw new Error('useClipLength must be used within a ClipLengthProvider');
    }

    return context;
};
