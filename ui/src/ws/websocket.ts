/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/ws/websocket.ts
  =====================
  Description:
    WebSocket client implementation
  ---
  Exports & Exported Components:
    - wsClient : The WebSocket client instance
  ---
  Globals:
    None
*/

import { nuiLog } from '../lib/nui';
import { DEFAULTS } from './defaults';
//=-- WebSocket client public module: types + implementation
import type {
    CloseHandler,
    ErrorHandler,
    MessageHandler,
    OpenHandler,
    WsConfig,
    WsEnvelope,
    WsEvent,
    WsHandler,
} from './types';

export * from './types';

/** Build a WebSocket URL from configuration
 * @internal
 */
function buildUrl(cfg: WsConfig): string {
    const protocol = cfg.protocol ?? DEFAULTS.protocol;
    const host = cfg.host ?? DEFAULTS.host;
    const port = cfg.port ?? DEFAULTS.port;
    const path = cfg.path ?? DEFAULTS.path ?? '';
    const normalizedPath = path ? (path.startsWith('/') ? path : `/${path}`) : '';
    return `${protocol}://${host}:${port}${normalizedPath}`;
}

/**
 * Minimal WebSocket client wrapper.
 *
 * Provides a simple API to: connect, send, close, and subscribe to events.
 */
class WsClient {
    /** Internal state */
    private ws: WebSocket | null = null;
    private cfg: WsConfig = { ...DEFAULTS };

    /** Listener registries */
    private onMessageHandlers = new Set<MessageHandler>();
    private onOpenHandlers = new Set<OpenHandler>();
    private onErrorHandlers = new Set<ErrorHandler>();
    private onCloseHandlers = new Set<CloseHandler>();

    /** Reconnect config/state */
    private reconnectShortMs = 30_000; //=-- First background retry delay
    private reconnectLongMs = 120_000; //=-- Subsequent silent retry delay
    private reconnectShortAttempts = 5; //=-- Number of short retries before switching to long interval
    private shortAttemptsMade = 0; //=-- Counter for short attempts in the current disconnect cycle
    private reconnectTimer: number | null = null; //=-- Long-interval timer id
    private shortReconnectTimer: number | null = null; //=-- Short-interval timer id
    private intentionalClose = false;
    private silentReconnect = false; //=-- When true, do not log every attempt

    /**
     * Connect or reconnect the client.
     *
     * Creates a new WebSocket using the last known configuration merged with the provided `cfg`.
     * If an existing socket is open or connecting, it is closed first with code `1000` and reason "reconnect".
     *
     * @param cfg - Optional configuration overrides
     */
    connect = (cfg?: WsConfig) => {
        if (cfg) {
            this.cfg = { ...this.cfg, ...cfg };
            //=-- Optional reconnect intervals from config
            if (typeof cfg.reconnectShortMs === 'number') this.reconnectShortMs = cfg.reconnectShortMs;
            if (typeof cfg.reconnectLongMs === 'number') this.reconnectLongMs = cfg.reconnectLongMs;
            if (typeof cfg.reconnectShortAttempts === 'number') this.reconnectShortAttempts = cfg.reconnectShortAttempts;
        }

        //=-- New connect attempt cancels any existing reconnect loop
        if (this.reconnectTimer !== null) {
            try {
                clearInterval(this.reconnectTimer);
            } catch {
                //=-- noop
            }
            this.reconnectTimer = null;
        }
        if (this.shortReconnectTimer !== null) {
            try {
                clearInterval(this.shortReconnectTimer);
            } catch {
                //=-- noop
            }
            this.shortReconnectTimer = null;
        }
        this.intentionalClose = false;
        this.shortAttemptsMade = 0;

        //=-- Close any existing socket before reconnect
        if (
            this.ws &&
            (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING)
        ) {
            try {
                this.ws.close(1000, 'reconnect');
            } catch {
                //=-- noop
            }
        }

        const url = buildUrl(this.cfg);
        this.ws = new WebSocket(url);

        this.ws.addEventListener('open', (ev) => {
            this.emit('open', ev);
            //=-- Cancel reconnect loop on successful open
            if (this.reconnectTimer !== null) {
                try {
                    clearInterval(this.reconnectTimer);
                } catch {
                    //=-- noop
                }
                this.reconnectTimer = null;
            }
            if (this.shortReconnectTimer !== null) {
                try {
                    clearInterval(this.shortReconnectTimer);
                } catch {
                    //=-- noop
                }
                this.shortReconnectTimer = null;
            }
            this.silentReconnect = false;
            this.shortAttemptsMade = 0;
            try {
                void nuiLog(`[ws] connected: ${url}`, 'info');
            } catch {
                //=-- noop
            } //=-- Log connection
        });

        this.ws.addEventListener('message', (ev) => {
            let env: WsEnvelope;
            try {
                const parsed = JSON.parse(String(ev.data));
                if (parsed && typeof parsed === 'object' && typeof parsed.type === 'string') {
                    env = parsed as WsEnvelope;
                } else {
                    //=-- Fallback: Wrap non-envelope JSON into a raw envelope
                    env = { type: 'raw', data: parsed };
                }
            } catch {
                //=-- Fallback: Toss non-JSON into a raw envelope
                env = { type: 'raw', data: ev.data };
            }
            for (const h of this.onMessageHandlers) h(env, ev);
        });

        this.ws.addEventListener('error', (ev) => {
            this.emit('error', ev);
        });

        this.ws.addEventListener('close', (ev) => {
            this.emit('close', ev);
            this.ws = null; //=-- Mark the socket closed

            //=-- Log the dropped connection only once before entering silent reconnect
            if (!this.silentReconnect) {
                try {
                    void nuiLog(
                        `[ws] connection dropped (code=${(ev as CloseEvent).code}, reason=${(ev as CloseEvent).reason || 'n/a'})`,
                        'warning',
                    );
                } catch {
                    //=-- noop
                }
            }

            //=-- Start the reconnect loop, if it was not intentionally closed
            if (!this.intentionalClose && this.reconnectTimer === null && this.shortReconnectTimer === null) {
                //=-- Announce one time that we will retry silently: first after short delay, then every long delay
                try {
                    const shortSec = Math.max(1, Math.round(this.reconnectShortMs / 1000));
                    const longSec = Math.max(1, Math.round(this.reconnectLongMs / 1000));
                    void nuiLog(`[ws] disconnected; retrying in ${shortSec}s, then silently every ${longSec}s`, 'warning');
                } catch {
                    //=-- noop
                }
                this.silentReconnect = true;

                const attempt = () => {
                    try {
                        //=-- If it is already open/connecting, skip
                        if (
                            this.ws &&
                            (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING)
                        ) {
                            return;
                        }
                        //=-- Attempt reconnection (silent)
                        this.connect();
                    } catch {
                        //=-- ignore
                    }
                };

                //=-- Short-interval attempts up to N times
                this.shortAttemptsMade = 0;
                this.shortReconnectTimer = window.setInterval(() => {
                    if (this.shortAttemptsMade >= this.reconnectShortAttempts) {
                        //=-- Switch to long interval loop
                        try {
                            clearInterval(this.shortReconnectTimer!);
                        } catch {
                            //=-- noop
                        }
                        this.shortReconnectTimer = null;
                        if (this.reconnectTimer === null) {
                            this.reconnectTimer = window.setInterval(() => {
                                attempt();
                            }, this.reconnectLongMs);
                        }
                        return;
                    }
                    this.shortAttemptsMade++;
                    attempt();
                }, this.reconnectShortMs);
            }
        });
    };

    /**
     * Close the current WebSocket connection.
     *
     * @param code - Optional close code
     * @param reason - Optional human-readable reason
     */
    close = (code?: number, reason?: string) => {
        this.intentionalClose = true; //=-- Prevent auto-reconnect, as this is intentional

        if (this.reconnectTimer !== null) {
            try {
                clearInterval(this.reconnectTimer);
            } catch {
                //=-- noop
            }
            this.reconnectTimer = null;
        }

        if (!this.ws) return;

        try {
            this.ws.close(code, reason);
        } catch {
            //=-- noop
        }
        this.ws = null;
    };

    /**
     * Send a JSON envelope over the WebSocket.
     *
     * Usage:
     *  - send('type', data?)
     *  - send({ type, data? })
     *
     * @throws Error if the socket is not open
     */
    send(type: string, data?: unknown): void;
    send(envelope: WsEnvelope): void;
    send(arg1: string | WsEnvelope, data?: unknown): void {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
            throw new Error('WebSocket not open');
        }

        //=-- Normalize to envelope
        const env: WsEnvelope =
            typeof arg1 === 'string' ? { type: arg1, data } : (arg1 as WsEnvelope);

        try {
            this.ws.send(JSON.stringify(env));
        } catch {
            //=-- Fallback: Stringify to avoid sending "[object Object]"
            try {
                const seen = new WeakSet<object>();
                const json = JSON.stringify(env, (_k, v) => {
                    if (typeof v === 'bigint') return v.toString();
                    if (v && typeof v === 'object') {
                        if (seen.has(v as object)) return '[Circular]';
                        seen.add(v as object);
                    }
                    return v;
                });
                this.ws.send(json);
            } catch {
                //=-- Last resort: send a minimal, descriptive envelope
                const fallback = JSON.stringify({
                    type: env.type ?? 'raw',
                    data: '[Unserializable payload]',
                });
                this.ws.send(fallback);
            }
        }
    }

    /** Subscribe helpers */
    /**
     * Subscribe to message events.
     *
     * @param handler - The callback invoked on every message with the parsed data and the raw event
     * @returns Unsubscribe function
     */
    onMessage = (handler: MessageHandler) => {
        this.onMessageHandlers.add(handler);
        return () => this.onMessageHandlers.delete(handler);
    };

    /**
     * Subscribe to open events.
     * @param handler - The callback invoked when the socket opens
     * @returns Unsubscribe function
     */
    onOpen = (handler: OpenHandler) => this.add('open', handler);
    /**
     * Subscribe to error events.
     * @param handler - The callback invoked when the socket errors
     * @returns Unsubscribe function
     */
    onError = (handler: ErrorHandler) => this.add('error', handler);
    /**
     * Subscribe to close events.
     * @param handler - The callback invoked when the socket closes
     * @returns Unsubscribe function
     */
    onClose = (handler: CloseHandler) => this.add('close', handler);

    //=-- Internal emitter/add helpers
    private emit(event: 'open', ev: Event): void;
    private emit(event: 'message', ev: WsEnvelope): void;
    private emit(event: 'error', ev: Event): void;
    private emit(event: 'close', ev: CloseEvent): void;
    // biome-ignore lint/suspicious/noExplicitAny: function overload
    private emit(event: WsEvent, ev: any): void {
        const map: Record<WsEvent, Set<WsHandler>> = {
            open: this.onOpenHandlers,
            message: this.onMessageHandlers,
            error: this.onErrorHandlers,
            close: this.onCloseHandlers,
        };

        for (const h of map[event]) {
            try {
                h(ev, undefined);
            } catch {
              //=-- ignore listener error
            }
        }
    }

    private add = (event: Exclude<WsEvent, 'message'>, handler: WsHandler) => {
        const map: Record<Exclude<WsEvent, 'message'>, Set<WsHandler>> = {
            open: this.onOpenHandlers,
            error: this.onErrorHandlers,
            close: this.onCloseHandlers,
        };

        map[event].add(handler);
        return () => map[event].delete(handler);
    };
}

/** Shared instance of the WebSocket client */
export const wsClient = new WsClient();
export default wsClient;
