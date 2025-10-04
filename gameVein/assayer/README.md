# gameVein/assayer

The Assayer handles ore routing (client-sided to NUI/UI).
Framework detection has been moved to the shared `services/` framework detection service.

## Files

- `client-assayer.lua`
  - Routes ore requests to the correct ore type.
  - Supports bundling multiple ore requests into a single call.
    - API: `Medal.GV.Ore.assay(req: string|table): any`
    - Accepts `'type'` (string) or `{ type = string, ... }` (object).
    - Also accepts `{ type = 'bundle', types = { 'name', 'job' } }` to request multiple ores at once.

For framework detection, use the service APIs instead:

- Client: `Medal.Services.Framework.getKey(timeoutMs?: number): FrameworkKey`
- Server: `Medal.Services.Framework.detectFramework(forceRefresh?: boolean): FrameworkKey`

## Request Helpers

See `lib/shared-request.lua`:

- `Medal.GV.Request.buildId()`
- `Medal.GV.Request.await(pending, requestId, timeoutMs?, defaultValue)`

## Extending Ore Routing

The assayer now uses a lowercase-keyed dispatch table (case-insensitive lookup). To add a new ore type, add an entry to the dispatch after it is initialized. Keys must be lowercase; the `type` value should preserve the canonical casing, and `fn` should point to the ore function.

```lua
--//=-- gameVein/assayer/client-assayer.lua
-- After _oreDispatch is initialized inside Medal.GV.Ore.assay(req):
_oreDispatch.yourtype = { type = 'yourType', fn = Medal.GV.Ore.yourType }

-- Lookup is case-insensitive:
-- local key = string.lower(oreType)
-- local entry = _oreDispatch[key]
-- if entry then return entry.fn() end
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

### Proximity Fan-out (players around you)

You can request an ore (or a bundle of ores) from nearby players by adding `radius` to any request. This is compatible with OneSync Infinity.

- Single ore: `{ type: 'job', radius?: number, maxPlayers?: number, timeoutMs?: number }`
- Bundle: `{ type: 'bundle', types: { 'name', 'job' }, radius?: number, maxPlayers?: number, timeoutMs?: number }`

Return value is a table of tables: `[ selfData, others ]`

- `selfData`: The invoking player's data for the requested ore(s).
- `others`: An array of wrappers, each shaped `{ id, name, data }` where:
  - `id` is the nearby player's server id
  - `name` is the nearby player's FiveM name
  - `data` is the ore result (or bundle table) for that player

Examples:

```lua
--//=-- Single ore from nearby players (preferred modern usage)
local selfJob, others = table.unpack(Medal.GV.Ore.assay({ type = 'job', radius = 60.0, maxPlayers = 5 }))
for _, entry in ipairs(others) do
  print(('nearby id=%d name=%s'):format(entry.id, entry.name))
  print(('job: %s %d'):format(entry.data.name or 'unknown', entry.data.rank or -1))
end

--//=-- Bundle from nearby players
local selfBundle, othersBundles = table.unpack(Medal.GV.Ore.assay({ type = 'bundle', types = { 'name', 'job' }, radius = 80.0, maxPlayers = 5 }))
-- selfBundle is a table keyed by ore type, e.g., { name = {...}, job = {...} }
for _, entry in ipairs(othersBundles) do
  print(('nearby id=%d name=%s'):format(entry.id, entry.name))
  local bundle = entry.data
  -- bundle mirrors the structure for the requester
  -- example: bundle.name, bundle.job
end
```

Events used:

- Client -> Server: `medal:gv:assayer:reqNearby` to initiate a nearby query
- Server -> Client: `medal:gv:assayer:reqFromServer` to ask a client to assay on behalf of the invoker
- Client -> Server: `medal:gv:assayer:resFromClient` to send back the assayed data
- Server -> Client: `medal:gv:assayer:resNearby` to deliver the aggregated results back to the invoker

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
