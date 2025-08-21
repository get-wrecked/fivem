//=-- WebSocket client public module: types + implementation
import { WsConfig, WsEvent, MessageHandler, OpenHandler, ErrorHandler, CloseHandler, WsEnvelope } from './types';
import { DEFAULTS } from './defaults';
export * from './types';

/** Build a WebSocket URL from configuration
 * @internal
 */
function buildUrl(cfg: WsConfig): string {
  const protocol = cfg.protocol ?? DEFAULTS.protocol;
  const host = cfg.host ?? DEFAULTS.host;
  const port = cfg.port ?? DEFAULTS.port;
  const path = (cfg.path ?? DEFAULTS.path) ?? '';
  const normalizedPath = path ? (path.startsWith('/') ? path : `/${path}`) : '';
  return `${protocol}://${host}:${port}${normalizedPath}`;
}

/** Minimal WebSocket client wrapper
 * Provides a simple API to connect, send, close, and subscribe to events.
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

  /** Connect or reconnect the client
    * Creates a new WebSocket using the last known configuration merged with the provided `cfg`.
    * If an existing socket is open or connecting, it is closed first with code `1000` and reason "reconnect".
    * @param cfg - Optional configuration overrides
    */
  connect = (cfg?: WsConfig) => {
    if (cfg) this.cfg = { ...this.cfg, ...cfg };

    //=-- Close any existing socket before reconnect
    if (this.ws && (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING)) {
      try { this.ws.close(1000, 'reconnect'); } catch { /*//=-- noop */ }
    }

    const url = buildUrl(this.cfg);
    this.ws = new WebSocket(url);

    this.ws.addEventListener('open', (ev) => {
      this.emit('open', ev);
    });

    this.ws.addEventListener('message', (ev) => {
      let env: WsEnvelope;
      try {
        const parsed = JSON.parse(String(ev.data));
        if (parsed && typeof parsed === 'object' && typeof (parsed as any).type === 'string') {
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
    });
  };

  /** Close the current WebSocket connection
    * @param code - Optional close code
    * @param reason - Optional human-readable reason
    */
  close = (code?: number, reason?: string) => {
    if (!this.ws) return;
    try { this.ws.close(code, reason); } catch { /*//=-- noop */ }
    this.ws = null;
  };

  /** Send a JSON envelope over the WebSocket
    * Usage:
    *  - send('type', data?)
    *  - send({ type, data? })
    * @throws Error if the socket is not open
    */
  send(type: string, data?: unknown): void;
  send(envelope: WsEnvelope): void;
  send(arg1: string | WsEnvelope, data?: unknown): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      throw new Error('WebSocket not open');
    }

    //=-- Normalize to envelope
    const env: WsEnvelope = typeof arg1 === 'string'
      ? { type: arg1, data }
      : (arg1 as WsEnvelope);

    try {
      this.ws.send(JSON.stringify(env));
    } catch {
      //=-- Last resort string
      this.ws.send(String(env as any));
    }
  }

  /** Subscribe helpers */
  /** Subscribe to message events
    * @param handler - Callback invoked on every message with parsed data and the raw event
    * @returns Unsubscribe function
    */
  onMessage = (handler: MessageHandler) => {
    this.onMessageHandlers.add(handler);
    return () => this.onMessageHandlers.delete(handler);
  };

  /** Subscribe to open events */
  onOpen = (handler: OpenHandler) => this.add('open', handler);
  /** Subscribe to error events */
  onError = (handler: ErrorHandler) => this.add('error', handler);
  /** Subscribe to close events */
  onClose = (handler: CloseHandler) => this.add('close', handler);

  //=-- Internal emitter/add helpers
  private emit = (event: WsEvent, ev: any) => {
    const map: Record<WsEvent, Set<Function>> = {
      open: this.onOpenHandlers as any,
      message: this.onMessageHandlers as any,
      error: this.onErrorHandlers as any,
      close: this.onCloseHandlers as any,
    };
    for (const h of map[event]) {
      try { (h as any)(ev); } catch { /*//=-- ignore listener error */ }
    }
  };

  private add = (event: Exclude<WsEvent, 'message'>, handler: any) => {
    const map: Record<Exclude<WsEvent, 'message'>, Set<any>> = {
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
