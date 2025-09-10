# gameVein/assayer

The Assayer handles ore routing (client-sided to NUI/UI).
Framework detection has been moved to the shared `services/` framework detection service.

## Files

- `client-assayer.lua`
  - Routes ore requests to the correct ore type.
    - API: `Medal.GV.Ore.assay(req: string|table): any`
    - Accepts `'type'` (string) or `{ type = string, ... }` (object).

For framework detection, use the service APIs instead:
- Client: `Medal.Services.Framework.getKey(timeoutMs?: number): FrameworkKey`
- Server: `Medal.Services.Framework.detectFramework(forceRefresh?: boolean): FrameworkKey`

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
import { fetchNui } from '@tsfx/hooks';
await fetchNui('ws:minecart', { payload: { type: 'yourOreType' } });
// The POST returns an ACK; the actual object (`{ type: 'yourType', data }`), is forwarded via WebSocket.
```

## Direct Lua Usage (no WebSocket)

You can call the assayer directly from client-side, and get the ore data immediately.

- __Pure client ore__: Returns immediately.

```lua
--//=-- Ex: Directly from the ore
local hb = Medal.GV.Ore.assay('heartbeat')
if hb and hb.ok then
  print(('heartbeat ok=%s ts=%d pid=%d'):format(tostring(hb.ok), hb.ts, hb.pid))
end
```

- __Server-backed ore__: Internally triggers a server request and waits for the response using `Medal.GV.Request.await()`.
  - Default timeout is 5000 ms (see `lib/shared-request.lua`).
  - If the timeout elapses, the ore function returns its configured default value.

```lua
--//=-- Ex: Server-backed ore (see `gameVein/ore/client-job.lua`)
local job = Medal.GV.Ore.assay({ type = 'job' })
--//=-- On timeout, returns the default from the ore file (e.g., { name = 'unemployed', grade = 0 })
if job then
  print(('job=%s grade=%d'):format(job.name or 'unknown', job.grade or -1))
end
```

- __Call producers directly (optional)__: You can bypass the assayer and call specific ores.

```lua
--//=-- Ex: Call ore's producer directly
local name = Medal.GV.Ore.name()
print('player name', name)
```

Notes:
- `Medal.GV.Ore.assay(req)` accepts a string (the type), or a table (also the type, and not for eating) with `type = string`.
