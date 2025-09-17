/**
 * Medal.tv - FiveM Resource
 * =========================
 * File: ui/src/hooks/use-websocket-status.ts
 * =====================
 * Description:
 * The hook for the WebSocket status context.
 * ---
 * @exports useWebSocketStatus - The hook for the WebSocket status context.
 */

import { useContext } from 'react';
import {
    WebSocketStatusContext,
    type WebSocketStatusContextValue,
} from '@/contexts/websocket-status-context';

/**
 * Hook for the WebSocket status context.
 */
export const useWebSocketStatus = (): WebSocketStatusContextValue => {
    const context = useContext(WebSocketStatusContext);

    if (!context) {
        throw new Error('useWebSocketStatus must be used within a WebSocketStatusProvider.');
    }

    return context;
};
