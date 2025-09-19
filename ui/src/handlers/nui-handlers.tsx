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

import { fetchNui, useNuiEvent } from '@tsfx/hooks';
import type React from 'react';
import { useEffect } from 'react';
import { nuiLog } from '../lib/nui';
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
 * - inbound WebSocket messages: routes any message with a `type` to ore assay system
 * - messages without `type` are logged to console for debugging
 */
export const NuiHandlers: React.FC = () => {
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
                //=-- Debug: log envelope being emitted to WS
                try {
                    void nuiLog({ event: 'ws:send:emit', value }, 'debug');
                } catch {
                    //=-- ignore
                }
                //=-- String: Treated as a type only, with no data
                if (typeof value === 'string') {
                    wsClient.send(value);
                    return;
                }

                //=-- Object: With `{ type }` is considered an envelope already
                if (
                    value &&
                    typeof value === 'object' &&
                    'type' in value &&
                    typeof value.type === 'string'
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
            const code = v && typeof v === 'object' && 'code' in v ? v.code : undefined;
            const reason = v && typeof v === 'object' && 'reason' in v ? v.reason : undefined;
            wsClient.close(code, reason);
        },
    });

    //=-- WebSocket inbound message handling: routes any message with `type` to ore assay, logs others
    useEffect(() => {
        let mounted = true;
        const off = wsClient.onMessage((env) => {
            if (env?.type && (typeof env.type === 'string' || Array.isArray(env.type))) {
                //=-- Print the data via shared Lua logger
                void nuiLog(env.data, 'debug');

                //=-- Route any message with a type to the ore assay system
                (async () => {
                    try {
                        //=-- Simplified routing:
                        //=-- - string -> { type }
                        //=-- - string[] -> { type: 'bundle', types }
                        //=-- - 'bundle' with data.types -> { type: 'bundle', types }
                        let req: Record<string, unknown>;
                        if (Array.isArray(env.type)) {
                            req = { type: 'bundle', types: env.type };
                        } else if (
                            env.type === 'bundle' &&
                            env.data &&
                            typeof env.data === 'object' &&
                            Array.isArray((env.data as Record<string, unknown>).types)
                        ) {
                            req = {
                                type: 'bundle',
                                types: (env.data as Record<string, unknown>).types,
                            };
                        } else {
                            req = { type: env.type } as Record<string, unknown>;
                        }
                        //=-- Debug: show exact request to Lua
                        try {
                            void nuiLog({ event: 'ws:minecart:req', req }, 'debug');
                        } catch {
                            //=-- ignore
                        }
                        await fetchNui('ws:minecart', { payload: req });
                    } catch {
                        //=-- Return that the ore doesn't exist
                        wsClient.send(Array.isArray(env.type) ? 'bundle' : env.type, {
                            error: 'ore-unavailable',
                        });
                    }
                })();
            } else {
                //=-- No type property: log the exact payload to console
                console.log('[ws] Message received with no type:', env);
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
                        //=-- ignore
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
