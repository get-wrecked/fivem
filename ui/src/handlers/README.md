# ui/src/handlers

NUI event handlers that bridge UI actions with the LUA side, and the WebSocket client.

- `nui-handlers.tsx`
  - Subscribes to NUI messages to:
    - open a WebSocket (`ws:connect`)
    - send a message (`ws:send`)
    - close the socket (`ws:close`)
  - Handles inbound WebSocket messages:
    - Routes any message with a `type` property to the ore assay system via `ws:minecart`
    - Returns `{ error: 'ore-unavailable' }` if the ore type doesn't exist
    - Logs messages without a `type` property to console for debugging
  - Guards logging during the cleanup, to avoid logging post-unmount, when unavailable.

From the UI code, you can also call Lua NUI callbacks directly via `fetchNui` (see `ui/src/lib/nui.ts`). 

EX: Requesting a minecart full of ore:

```ts
import { fetchNui } from '@tsfx/hooks';

//=-- Ask Lua to assay an ore, and push it back over WS
await fetchNui('ws:minecart', { payload: { type: 'heartbeat' } });
```

## WebSocket Message Flow

When the server sends a WebSocket message:

1. **With `type` property**: `{"type":"name","data":null}`
   - Routes to `fetchNui('ws:minecart', { payload: { type: 'name' } })`
   - Lua assays the ore and sends response back over WebSocket
   - If ore doesn't exist, returns `{"type":"name","data":{"error":"ore-unavailable"}}`

2. **Without `type` property**: `{"data":"something"}`
   - Logs to console: `[ws] Message received with no type: {"data":"something"}`
