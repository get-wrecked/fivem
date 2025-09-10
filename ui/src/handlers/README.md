# ui/src/handlers

NUI event handlers that bridge UI actions with the LUA side, and the WebSocket client.

- `nui-handlers.tsx`
  - Subscribes to NUI messages to:
    - open a WebSocket (`ws:connect`)
    - send a message (`ws:send`)
    - close the socket (`ws:close`)
  - Guards logging during the cleanup, to avoid logging post-unmount, when unavailable.

From the UI code, you can also call Lua NUI callbacks directly via `fetchNui` (see `ui/src/lib/nui.ts`). 

EX: Requesting a minecart full of ore:

```ts
import { fetchNui } from '@tsfx/hooks';

//=-- Ask Lua to assay an ore, and push it back over WS
await fetchNui('ws:minecart', { payload: { type: 'heartbeat' } });
```
