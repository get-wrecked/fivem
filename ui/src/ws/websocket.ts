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

