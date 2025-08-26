# gameVein/assayer

The Assayer handles framework detection (mainly on the server side), and ore routing (client-sided to NUI/UI).

## Files

- `server-assayer.lua`
  - Detects which framework is running using resource state checks.
    - API: `Medal.GV.Assayer.detectFramework(forceRefresh?: boolean): FrameworkKey`
    - Search order (first match wins): ESX -> QB -> QBX -> ND -> OX -> TMC.
- `client-assayer.lua`
  - Routes ore requests to the correct ore type.
    - API: `Medal.GV.Ore.assay(req: string|table): any`
    - Accepts `'type'` (string) or `{ type = string, ... }` (object).
  - Client helper: `Medal.GV.Assayer.getFrameworkKey(timeoutMs?: number): FrameworkKey` (request/await pattern).

## Request Helpers

See `lib/shared-request.lua`:
- `Medal.GV.Request.buildId()`
- `Medal.GV.Request.await(pending, requestId, timeoutMs?, defaultValue)`

## Extending Ore Routing

To add a new ore type, include another branch in `Medal.GV.Ore.assay()`:

```lua
--//=-- gameVein/assayer/client-assayer.lua
if oreType == 'yourType' then
  return Medal.GV.Ore.yourType()
end
```

## How It's Interacted With

The assayer is invoked when the UI posts to the NUI endpoint `ws:minecart`.
The callback in `gameVein/shaft/client-minecart.lua`, calls `Medal.GV.Ore.assay(req)`, then ships the result back to the UI
as a WebSocket envelope ("minecart"), using `Medal.GV.pushMinecart(type, data)` (NUI `ws:send`).

<!--- TODO: Update for minecart expansion for non-WebSocket responses -->

From the UI, request the ore like this (the payload will arrive over the WebSocket, not as the POST response):

```ts
// ui
import { nuiPost } from '@/lib/nui';
await nuiPost('ws:minecart', { type: 'yourType' });
// The POST returns an ACK; the actual object (`{ type: 'yourType', data }`), is forwarded via WebSocket.
```