/**
 * Medal.tv - FiveM Resource
 * =========================
 * File: ui/src/hooks/use-api-status.ts
 * =====================
 * Description:
 * The hook for the API status context.
 * ---
 * @exports useApiStatus - The hook for the API status context.
 */

import { useContext } from 'react';
import { ApiStatusContext, type ApiStatusContextValue } from '@/contexts/api-status-context';

/**
 * Hook for the API status context.
 */
export const useApiStatus = (): ApiStatusContextValue => {
    const context = useContext(ApiStatusContext);

    if (!context) {
        throw new Error('useApiStatus must be used within a ApiStatusProvider.');
    }

    return context;
};
