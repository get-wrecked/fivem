/**
 * The WebSocket client types
 * @packageDocumentation
 */

export type WsProtocol = 'ws' | 'wss';

export interface WsConfig {
  /**
   * Hostname or IP address
   * @defaultValue "127.0.0.1"
   */
  host?: string;
  /**
   * TCP port to connect to
   * @defaultValue 63325
   */
  port?: number;
  /**
   * WebSocket protocol scheme
   * @defaultValue "ws"
   */
  protocol?: WsProtocol;
  /**
   * Optional path suffix appended to the URL (e.g. "/socket")
   */
  path?: string;
}

export type WsEvent = 'open' | 'message' | 'error' | 'close';

/**
 * Handler invoked when a message is received
 * @param data - Parsed payload if JSON, otherwise the raw data value
 * @param raw - The original browser `MessageEvent`
 */
export type MessageHandler = (data: unknown, raw: MessageEvent) => void;

/**
 * Handler invoked when the socket opens
 */
export type OpenHandler = (ev: Event) => void;

/**
 * Handler invoked when an error occurs on the socket
 */
export type ErrorHandler = (ev: Event) => void;

/**
 * Handler invoked when the socket closes
 */
export type CloseHandler = (ev: CloseEvent) => void;
