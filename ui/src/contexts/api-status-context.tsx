/**
 * Medal.tv - FiveM Resource
 * =========================
 * File: ui/src/contexts/api-status-context.tsx
 * =====================
 * Description:
 * The API status context for the UI.
 * ---
 * @exports ApiStatusContext - The API status context.
 * @exports ApiStatusContextValue - The API status context's value interface.
 */

import { createContext } from 'react';

/**
 * The value of the API status context.
 */
export interface ApiStatusContextValue {
    /**
     * Whether the autoclipping API is available.
     */
    isAvailable: boolean;
}

export const ApiStatusContext = createContext<ApiStatusContextValue>({
    isAvailable: false,
});
