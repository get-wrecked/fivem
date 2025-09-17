/**
 * Medal.tv - FiveM Resource
 * =========================
 * File: ui/src/contexts/websocket-status-context.tsx
 * =====================
 * Description:
 * The WebSocket status context for the UI.
 * ---
 * @exports WebSocketStatusContext - The WebSocket status context.
 * @exports WebSocketStatusContextValue - The WebSocket status context's value interface.
 */

import { createContext } from 'react';

/**
 * The value of the WebSocket status context.
 */
export interface WebSocketStatusContextValue {
    /**
     * Whether the WebSocket is connected.
     */
    isConnected: boolean;
}

export const WebSocketStatusContext = createContext<WebSocketStatusContextValue>({
    isConnected: false,
});
