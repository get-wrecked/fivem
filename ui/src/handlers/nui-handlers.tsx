import React from 'react';
import { useNuiEvent, useNuiVisibility } from '@tsfx/hooks';
import wsClient from '../ws/websocket';
import type { WsConfig } from '../ws/types';

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
    //=-- Send arbitrary payload over the socket. Will stringify non-string payloads.
    useNuiEvent<unknown>('ws:send', {
        handler: (payload) => {
            try {
                wsClient.send(payload);
            } catch {
                //=-- Socket not open; ignore
            }
        },
    });
    //=-- Ex: Add more handlers below as your server/client scripts emit events
    //=-- useNuiEvent<TypeGoesHere>('your:event:name', { handler: (payload) => { /*//=-- do thing */ } });

    return null;
};

export default NuiHandlers;
