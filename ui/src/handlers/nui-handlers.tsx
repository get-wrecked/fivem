/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/handlers/nui-handlers.tsx
  =====================
  Description:
    The NUI message handlers component
  ---
  Exports & Exported Components:
    - NuiHandlers : The NUI message handlers component
  ---
  Globals:
    None
*/

import { useNuiEvent, useNuiVisibility } from '@tsfx/hooks';
import type React from 'react';
import { useEffect } from 'react';
import { nuiLog, nuiPost } from '../lib/nui';
import type { WsConfig, WsEnvelope } from '../ws/types';
import wsClient from '../ws/websocket';
/**
 * NUI message handlers component.
 *
 * Registers LUA/CFX to UI listeners. Uses `@tsfx/hooks`
 * for subscriptions and delegates WebSocket control to `wsClient`.
 *
 * Handled actions:
 * - `ui:setVisible`, `ui:open`, `ui:close`
 * - `ws:connect`, `ws:send`, `ws:close`
 * - inbound `heartbeat` with optional `request` echo via minecart
 */
export const NuiHandlers: React.FC = () => {
    const { setVisible } = useNuiVisibility();

    //=-- Visibility controls
    useNuiEvent<boolean>('ui:setVisible', {
        handler: (v) => setVisible(Boolean(v)),
    });

    useNuiEvent<void>('ui:open', {
        handler: () => setVisible(true),
    });

    useNuiEvent<void>('ui:close', {
        handler: () => setVisible(false),
    });

    //=-- WebSocket controls from LUA to UI
    //=-- Connect with optional config (host/port/protocol/path). Defaults to ws://127.0.0.1:12556
    useNuiEvent<WsConfig | undefined>('ws:connect', {
        handler: (cfg) => {
            wsClient.connect(cfg ?? {});
        },
    });

    //=-- Send a JSON envelope over the socket: { type: string, data?: unknown }
    //=-- Accepts either a string (treated as the type), an envelope object, or any other value wrapped as { type: 'raw', data: value }
    useNuiEvent<unknown>('ws:send', {
        handler: (value) => {
            try {
                //=-- String: Treated as a type only, with no data
                if (typeof value === 'string') {
                    wsClient.send(value);
                    return;
                }

                //=-- Object: With `{ type }` is considered an envelope already
                if (
                    value &&
                    typeof value === 'object' &&
                    'type' in (value as any) &&
                    typeof (value as any).type === 'string'
                ) {
                    wsClient.send(value as WsEnvelope);
                    return;
                }

                //=-- Fallback: Attempt to wrap the arbitrary value into a raw envelope
                wsClient.send({ type: 'raw', data: value } as WsEnvelope);
            } catch (err) {
                //=-- Socket closed; log error
                void nuiLog({ event: 'ws:send:failed', error: err }, 'error');
            }
        },
    });

    //=-- Close the socket, optionally with code/reason
    useNuiEvent<{ code?: number; reason?: string } | undefined>('ws:close', {
        handler: (v) => {
            const code = v && typeof v === 'object' && 'code' in v ? (v as any).code : undefined;
            const reason =
                v && typeof v === 'object' && 'reason' in v ? (v as any).reason : undefined;
            wsClient.close(code, reason);
        },
    });

    //=-- WebSocket inbound message handling (e.g., heartbeat, name, communityName, etc)
    useEffect(() => {
        let mounted = true;
        const off = wsClient.onMessage((env) => {
            if (env?.type === 'heartbeat') {
                //=-- Print the data via shared Lua logger
                void nuiLog(env.data, 'info');

                //=-- Replies over WebSocket when requested: Use the minecart to send the ore from Lua to NUI
                if ((env as WsEnvelope).data === 'request') {
                    (async () => {
                        try {
                            await nuiPost('ws:minecart', { type: 'heartbeat' });
                        } catch {
                            /*//=-- ignore */
                        }
                    })();
                }
            }
        });
        return () => {
            //=-- Determine if we were still mounted before cleanup; set unmounted immediately
            const wasMounted = mounted;
            mounted = false;
            try {
                off();
            } catch (err) {
                //=-- Avoid NUI logging post-unmount; fall back to console
                if (wasMounted) {
                    void nuiLog({ event: 'ws:onMessage:off-failed', err }, 'warning');
                } else {
                    try {
                        console.warn('[ws:onMessage:off-failed]', err);
                    } catch {
                        /*//=-- ignore */
                    }
                }
            }
        };
    }, []);

    //=-- Ex: Add more handlers below as your server/client scripts emit events
    //=-- useNuiEvent<TypeGoesHere>('your:event:name', { handler: (payload) => { /*//=-- do thing */ } });

    return null;
};

export default NuiHandlers;
