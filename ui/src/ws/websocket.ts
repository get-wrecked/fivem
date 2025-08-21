//=-- WebSocket client public module: types + implementation
import { WsConfig, WsEvent, MessageHandler, OpenHandler, ErrorHandler, CloseHandler } from './types';
export * from './types';

const DEFAULTS: Required<Pick<WsConfig, 'host' | 'port' | 'protocol'>> & Pick<WsConfig, 'path'> = {
  host: '127.0.0.1',
  port: 63325,
  protocol: 'ws',
  path: undefined,
};

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
      let parsed: unknown = ev.data;
      try {
        //=-- Attempt to parse JSON but fall back to raw data
        parsed = JSON.parse(String(ev.data));
      } catch { /*//=-- keep raw */ }
      for (const h of this.onMessageHandlers) h(parsed, ev);
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

  /** Send data over the WebSocket
    * If `data` is an object, it will be JSON-stringified. Strings, ArrayBuffers, and Blobs are sent as-is.
    * @throws Error if the socket is not open
    */
  send = (data: unknown) => {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      throw new Error('WebSocket not open');
    }

    if (typeof data === 'string' || data instanceof ArrayBuffer || data instanceof Blob) {
      this.ws.send(data as any);
      return;
    }

    try {
      this.ws.send(JSON.stringify(data));
    } catch (e) {
      //=-- Fallback: attempt stringify
      this.ws.send(String(data));
    }
  };

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
