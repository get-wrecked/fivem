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
import { useEffect, useState } from 'react';
import { WebSocketStatusContext } from '@/contexts/websocket-status-context';
import wsClient from '@/ws/websocket';

/**
 * The WebSocket status provider for the UI.
 */
export const WebSocketStatusProvider: React.FC<PropsWithChildren> = ({ children }) => {
    const [isConnected, setIsConnected] = useState(false);
    const { visible } = useNuiVisibility();

    useNuiEvent('MEDAL_WEBSOCKET_STATUS', {
        handler: setIsConnected,
    });

    //=-- React immediately to socket events for snappy updates
    useEffect(() => {
        //=-- Initialize from current socket state
        try {
            setIsConnected(wsClient.isConnected());
        } catch {
            //=-- ignore
        }

        const offOpen = wsClient.onOpen(() => setIsConnected(true));
        const offClose = wsClient.onClose(() => setIsConnected(false));
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
    }, []);

    //=-- Poll every few seconds while the UI is visible to catch any missed transitions
    useEffect(() => {
        if (!visible) return;
        //=-- Set immediately on visibility change
        try {
            setIsConnected(wsClient.isConnected());
        } catch {
            //=-- ignore
        }

        const id = window.setInterval(() => {
            try {
                setIsConnected(wsClient.isConnected());
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
    }, [visible]);

    return (
        <WebSocketStatusContext.Provider value={{ isConnected }}>
            {children}
        </WebSocketStatusContext.Provider>
    );
};
