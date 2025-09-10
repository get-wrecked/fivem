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
