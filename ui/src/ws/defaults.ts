import type { WsConfig } from './types';

//=-- WebSocket client defaults
export const DEFAULTS: Required<Pick<WsConfig, 'host' | 'port' | 'protocol'>> & Pick<WsConfig, 'path'> = {
  host: '127.0.0.1',
  port: 63325,
  protocol: 'ws',
  path: undefined,
};
