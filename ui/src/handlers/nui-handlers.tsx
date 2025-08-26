import React, { useEffect } from 'react';
import { useNuiEvent, useNuiVisibility } from '@tsfx/hooks';
import wsClient from '../ws/websocket';
import type { WsConfig, WsEnvelope } from '../ws/types';
import { nuiLog, nuiPost } from '../lib/nui';

//=-- Centralized NUI message listeners for messages coming from Lua/CFX
//=-- This component registers event handlers via @tsfx/hooks and renders nothing
export const NuiHandlers: React.FC = () => {
    const { setVisible } = useNuiVisibility();

    //=-- Visibility controls (common pattern)
    useNuiEvent<boolean>('ui:setVisible', {
        handler: (v) => setVisible(Boolean(v)),
    });

    useNuiEvent<void>('ui:open', {
        handler: () => setVisible(true),
    });

    useNuiEvent<void>('ui:close', {
        handler: () => setVisible(false),
    });

    //=-- WebSocket controls from Lua → UI
    //=-- Connect with optional config (host/port/protocol/path). Defaults to ws://127.0.0.1:63325
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
                if (value && typeof value === 'object' && 'type' in (value as any) && typeof (value as any).type === 'string') {
                    wsClient.send(value as WsEnvelope);
                    return;
                }

                //=-- Fallback: Attempt to wrap the arbitrary value into a raw envelope
                wsClient.send({ type: 'raw', data: value } as WsEnvelope);
            } catch {
                //=-- Socket closed; ???
                // TODO: Log error
            }
        },
    });

    //=-- Close the socket, optionally with code/reason
    useNuiEvent<{ code?: number; reason?: string } | void>('ws:close', {
        handler: (v) => {
            const code = (v && typeof v === 'object' && 'code' in v) ? (v as any).code : undefined;
            const reason = (v && typeof v === 'object' && 'reason' in v) ? (v as any).reason : undefined;
            wsClient.close(code, reason);
        },
    });

    //=-- WebSocket inbound message handling (e.g., heartbeat, name, communityName, etc)
    useEffect(() => {
        const off = wsClient.onMessage((env) => {
            if (env?.type === 'heartbeat') {
                //=-- Print the data via shared Lua logger
                void nuiLog(env.data, 'info');

                //=-- Replies over WebSocket when requested: Use the minecart to send the ore from Lua to NUI
                if ((env as WsEnvelope).data === 'request') {
                    (async () => {
                        try {
                            await nuiPost('ws:minecart', { type: 'heartbeat' });
                        } catch { /*//=-- ignore */ }
                    })();
                }
            }
        });
        return () => { try { off(); } catch (err) { /*//=-- log cleanup failure */ void nuiLog({ event: 'ws:onMessage:off-failed', err }, 'warning'); } };
    }, []);

    //=-- Ex: Add more handlers below as your server/client scripts emit events
    //=-- useNuiEvent<TypeGoesHere>('your:event:name', { handler: (payload) => { /*//=-- do thing */ } });

    return null;
};

export default NuiHandlers;
