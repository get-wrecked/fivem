/**
 * Medal.tv - FiveM Resource
 * =========================
 * File: ui/src/providers/api-status-provider.tsx
 * =====================
 * Description:
 * The API status provider for the UI.
 * ---
 * @exports ApiStatusProvider - The API status provider.
 */

import { ApiStatusContext } from '@/contexts/api-status-context';
import { useNuiEvent } from '@tsfx/hooks';
import type { PropsWithChildren } from 'react';
import { useState } from 'react';

/**
 * The API status provider for the UI.
 */
export const ApiStatusProvider: React.FC<PropsWithChildren> = ({ children }) => {
    const [isAvailable, setIsAvailable] = useState(false);

    useNuiEvent('MEDAL_API_STATUS', {
        handler: setIsAvailable,
    });

    return (
        <ApiStatusContext.Provider value={{ isAvailable }}>
            {children}
        </ApiStatusContext.Provider>
    );
};
