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
   * @defaultValue 12556
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
 * A JSON envelope for our WebSocket messages
 * Always includes a required `type` string, but has an optional `data` payload
 */
export interface WsEnvelope {
  /** Message kind discriminator */
  type: string;
  /** Optional payload */
  data?: unknown;
}

/**
 * The vehicle information payload that is returned by the `vehicle` ore.
 *
 * @remarks
 * Provides the spawn identifier and vehicle class metadata for the current (or last) vehicle.
 *
 * @property id - Spawn name string (best-effort) that hashes to `hash`.
 * @property name - Human-readable display name or localized label.
 * @property hash - GTA model hash (integer) usable with spawn/create APIs.
 * @property class - GTA numeric vehicle class id.
 * @property className - Friendly vehicle class label (e.g., "Sports", "Super").
 */
export interface VehicleInfo {
  /** Spawn name string that hashes to `hash` (best-effort) */
  id: string;
  /** Human-readable display name or localized label */
  name: string;
  /** GTA model hash of the vehicle (use with CreateVehicle, etc.) */
  hash: number;
  /** GTA numeric vehicle class id */
  class: number;
  /** Friendly vehicle class label (e.g., "Sports", "Super") */
  className: string;
}

/**
 * Handler invoked when a message is received
 * @param data - Parsed JSON envelope with a `type` required, and an optional `data`
 * @param raw - The original browser `MessageEvent`
 * @returns void
 */
export type MessageHandler = (data: WsEnvelope, raw: MessageEvent) => void;

/**
 * Handler invoked when the socket opens
 * @param ev - The socket open event
 * @returns void
 */
export type OpenHandler = (ev: Event) => void;

/**
 * Handler invoked when an error occurs on the socket
 * @param ev - The socket error event
 * @returns void
 */
export type ErrorHandler = (ev: Event) => void;

/**
 * Handler invoked when the socket closes
 * @param ev - The socket close event (contains code/reason)
 * @returns void
 */
export type CloseHandler = (ev: CloseEvent) => void;
