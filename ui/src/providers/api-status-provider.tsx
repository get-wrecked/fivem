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
import { useNuiEvent, useNuiVisibility } from '@tsfx/hooks';
import type { PropsWithChildren } from 'react';
import { useEffect, useState } from 'react';
import { hasMedal } from '@/lib/medal';

/**
 * The API status provider for the UI.
 */
export const ApiStatusProvider: React.FC<PropsWithChildren> = ({ children }) => {
    const [isAvailable, setIsAvailable] = useState(false);
    const { visible } = useNuiVisibility();

    useNuiEvent('MEDAL_API_STATUS', {
        handler: setIsAvailable,
    });

    //=-- Poll every few seconds while the UI is visible for API availability
    useEffect(() => {
        if (!visible) return;
        let cancelled = false;

        const check = async () => {
            try {
                const ok = await hasMedal();
                if (!cancelled) setIsAvailable(ok);
            } catch {
                if (!cancelled) setIsAvailable(false);
            }
        };

        //=-- Run immediately on visibility change and then on an interval
        void check();
        const id = window.setInterval(() => { void check(); }, 3000);
        return () => {
            cancelled = true;
            try { clearInterval(id); } catch { /*//=-- ignore */ }
        };
    }, [visible]);

    return (
        <ApiStatusContext.Provider value={{ isAvailable }}>
            {children}
        </ApiStatusContext.Provider>
    );
};
