/**
 * Medal.tv - FiveM Resource
 * =========================
 * File: ui/src/providers/websocket-status-provider.tsx
 * =====================
 * Description:
 * The WebSocket status provider for the UI.
 * ---
 * @exports WebSocketStatusProvider - The WebSocket status provider.
 */

import { useNuiEvent, useNuiVisibility } from '@tsfx/hooks';
import type { PropsWithChildren } from 'react';
import { useCallback, useEffect, useState } from 'react';
import { WebSocketStatusContext } from '@/contexts/websocket-status-context';
import { nuiLog } from '@/lib/nui';
import wsClient from '@/ws/websocket';

/**
 * The WebSocket status provider for the UI.
 */
export const WebSocketStatusProvider: React.FC<PropsWithChildren> = ({ children }) => {
    const [isConnected, setIsConnected] = useState(false);
    const { visible } = useNuiVisibility();

    //=-- Log status changes with debug info
    const updateStatus = useCallback((status: boolean, source: string) => {
        setIsConnected((prevStatus) => {
            if (prevStatus !== status) {
                void nuiLog(
                    [
                        '[Medal WebSocket Status]',
                        `Changed from ${prevStatus} to ${status} (source: ${source})`,
                    ],
                    'info',
                );
            }
            return status;
        });
    }, []);

    useNuiEvent('MEDAL_WEBSOCKET_STATUS', {
        handler: (status: boolean) => updateStatus(status, 'NUI Event'),
    });

    //=-- React immediately to socket events for snappy updates
    useEffect(() => {
        //=-- Initialize from current socket state
        try {
            const currentStatus = wsClient.isConnected();
            updateStatus(currentStatus, 'Initial Check');
        } catch {
            //=-- ignore
        }

        const offOpen = wsClient.onOpen(() => updateStatus(true, 'WebSocket Open Event'));
        const offClose = wsClient.onClose(() => updateStatus(false, 'WebSocket Close Event'));
        return () => {
            try {
                offOpen();
            } catch {
                //=-- ignore
            }
            try {
                offClose();
            } catch {
                //=-- ignore
            }
        };
    }, [updateStatus]);

    //=-- Poll every few seconds while the UI is visible to catch any missed transitions
    useEffect(() => {
        if (!visible) return;

        //=-- Log visibility state
        void nuiLog(['[Medal WebSocket Status]', `UI visible, starting polling checks`], 'debug');

        //=-- Set immediately on visibility change
        try {
            const currentStatus = wsClient.isConnected();
            updateStatus(currentStatus, 'Visibility Change');
        } catch {
            //=-- ignore
        }

        const id = window.setInterval(() => {
            try {
                const currentStatus = wsClient.isConnected();
                updateStatus(currentStatus, 'Polling Check');
            } catch {
                //=-- ignore
            }
        }, 3000);
        return () => {
            try {
                clearInterval(id);
            } catch {
                //=-- ignore
            }
        };
    }, [visible, updateStatus]);

    return (
        <WebSocketStatusContext.Provider value={{ isConnected }}>
            {children}
        </WebSocketStatusContext.Provider>
    );
};
