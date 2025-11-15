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

import { useNuiEvent, useNuiVisibility } from '@tsfx/hooks';
import type { PropsWithChildren } from 'react';
import { useCallback, useEffect, useState } from 'react';
import { ApiStatusContext } from '@/contexts/api-status-context';
import { Medal } from '@/lib/medal';
import { nuiLog } from '@/lib/nui';

/**
 * The API status provider for the UI.
 */
export const ApiStatusProvider: React.FC<PropsWithChildren> = ({ children }) => {
    const [isAvailable, setIsAvailable] = useState(false);
    const { visible } = useNuiVisibility();

    //=-- Log status changes with debug info
    const updateStatus = useCallback((status: boolean, source: string) => {
        setIsAvailable((prevStatus) => {
            if (prevStatus !== status) {
                void nuiLog(
                    [
                        '[Medal API Status]',
                        `Changed from ${prevStatus} to ${status} (source: ${source})`,
                    ],
                    'info',
                );
            }
            return status;
        });
    }, []);

    useNuiEvent('MEDAL_API_STATUS', {
        handler: (status: boolean) => updateStatus(status, 'NUI Event'),
    });

    //=-- Poll every few seconds while the UI is visible for API availability
    useEffect(() => {
        if (!visible) return;
        let cancelled = false;

        const check = async () => {
            try {
                const ok = await Medal.hasApp();
                if (!cancelled) updateStatus(ok, 'Polling Check');
            } catch (error) {
                void nuiLog(['[Medal API Status]', 'Check failed:', error], 'debug');
                if (!cancelled) updateStatus(false, 'Check Error');
            }
        };

        //=-- Log initial visibility state
        void nuiLog(['[Medal API Status]', `UI visible, starting polling checks`], 'debug');

        //=-- Run immediately on visibility change and then on an interval
        void check();
        const id = window.setInterval(() => {
            void check();
        }, 3000);
        return () => {
            cancelled = true;
            try {
                clearInterval(id);
            } catch {
                //=-- ignore
            }
        };
    }, [visible, updateStatus]);

    return (
        <ApiStatusContext.Provider value={{ isAvailable }}>{children}</ApiStatusContext.Provider>
    );
};
