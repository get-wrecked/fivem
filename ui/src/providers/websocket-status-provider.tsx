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

import { WebSocketStatusContext } from '@/contexts/websocket-status-context';
import { useNuiEvent } from '@tsfx/hooks';
import type { PropsWithChildren } from 'react';
import { useState } from 'react';

/**
 * The WebSocket status provider for the UI.
 */
export const WebSocketStatusProvider: React.FC<PropsWithChildren> = ({ children }) => {
    const [isConnected, setIsConnected] = useState(false);

    useNuiEvent('MEDAL_WEBSOCKET_STATUS', {
        handler: setIsConnected,
    });

    return (
        <WebSocketStatusContext.Provider value={{ isConnected }}>
            {children}
        </WebSocketStatusContext.Provider>
    );
};
