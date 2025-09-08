/*
  Medal.tv - FiveM Resource
  =========================
  File: ui/src/ws/defaults.ts
  =====================
  Description:
    The default WebSocket configuration
  ---
  Exports & Exported Components:
    - DEFAULTS : The default WebSocket configuration
  ---
  Globals:
    None
*/

import type { WsConfig } from './types';

/**
 * Default WebSocket configuration used by the UI client.
 *
 * @remarks
 *
 * These values are applied whenever a corresponding field is omitted in `WsConfig`.
 * The `path` is optional and omitted by default.
 */
export const DEFAULTS: Required<Pick<WsConfig, 'host' | 'port' | 'protocol'>> &
    Pick<WsConfig, 'path'> = {
    host: '127.0.0.1',
    port: 12556,
    protocol: 'ws',
    path: undefined,
};
