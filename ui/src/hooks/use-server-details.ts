import { useContext } from 'react';
import {
    ServerDetailsContext,
    type ServerDetailsContextValue,
} from '@/contexts/server-details-context';

export const useServerDetails = (): ServerDetailsContextValue => {
    const context = useContext(ServerDetailsContext);

    if (!context) {
        throw new Error('useServerDetails must be used within a ServerDetailsProvider.');
    }

    return context;
};
