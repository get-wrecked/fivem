# ui/src/ws

The WebSocket client, used by NUI/UI.

- `websocket.ts` - The `WsClient` implementation, and `wsClient` the singleton export.
- `types.ts` - `WsConfig`, events, and the `WsEnvelope` shape.
- `defaults.ts` - Defines the default host, port, protocol, and path.

## API (WsClient)

- `connect(cfg?: WsConfig)` - Connects or reconnects to the WebSocket, with optional config overrides.
- `close(code?: number, reason?: string)` - Intentionally closes the WebSocket (disables the auto-reconnect).
- `send(type: string, data?: unknown)` or `send(envelope: WsEnvelope)` - Sends a JSON data envelope over the WebSocket.
- `onMessage(handler)` / `onOpen(handler)` / `onError(handler)` / `onClose(handler)` - This subscribes to WebSocket events, and returns an `unsubscribe()` function.

### Reconnect behavior

- On disconnect, the client logs a single warning that it will retry after a short delay, then silently on a longer interval.
- The first retries occur every `reconnectShortMs` (default 30000ms) for up to `reconnectShortAttempts` times (default 5).
- After the short attempts, subsequent retries occur every `reconnectLongMs` (default 120000ms), without spamming the console.
- You can override these by passing them in the initial `connect(cfg)` call; they are also forwarded from Lua via `Config.GameVein.WebSocket`.

```ts
wsClient.connect({ reconnectShortMs: 15_000, reconnectLongMs: 90_000, reconnectShortAttempts: 3 });
```

## Examples

```ts
import wsClient from '@/ws/websocket';

//=-- Connect
wsClient.connect({ host: '127.0.0.1', port: 12556, protocol: 'ws' });

//=-- Listen for, and respond to, WebSocket messages
const off = wsClient.onMessage((env) => {
  console.log('message', env.type, env.data);
});

//=-- Send an WebSocket message
wsClient.send('hello', { msg: 'from ui' });

//=-- Close the WebSocket client's connection
wsClient.close();
```
