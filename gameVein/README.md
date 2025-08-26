# GameVein

GameVein is the in-resource data pipeline that extracts (mines) small, typed chunks of game data ("ores"), routes them (the "assayer"), and ships them to the UI over NUI/WebSocket transports (the "shaft" and "minecarts").

- __ore/__
  - Functions that return specific pieces of data (ex: `name`, `communityName`, `heartbeat`).
- __assayer/__
  - Detection and routing helpers. 
    - Maps ore type strings to the correct `Medal.GV.Ore.*()` producer.
    - Detects which framework is active on the server.
- __shaft/__
  - Transport helpers. Opens/closes the UI WebSocket, and sends the resulting envelopes ("minecarts").
- `client-main.lua`
  - Reads the WebSocket config from `Config.GameVein.*` and asks the UI to connect via NUI `ws:connect`.
- `server-main.lua`
  - Placeholder for future server-side logic.
- `__types.lua`
  - Type aliases, shared by GameVein (ex: `FrameworkKey`, and `WsProtocol`).

## Data Flow Overview

1) NUI/UI triggers `ws:connect` to open the WebSocket, or the resource does (on start), via `Medal.GV.openUiWebSocket()` in `gameVein/client-main.lua`.
2) UI/NUI posts to the NUI endpoint (`ws:minecart`), with an ore request to be assayed (ex: `{ type = 'heartbeat' }`).
3) `gameVein/shaft/client-minecart.lua` calls `Medal.GV.Ore.assay(req)`, which routes to the correct ore function, and then sends it back to the NUI/UI, using `Medal.GV.pushMinecart(type, data)`.

## Adding a New Ore type (quick start)

1) __Create a new function__ in `gameVein/ore/` that returns the ore payload.

```lua
--//=-- gameVein/ore/client-job.lua
Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

--- Return the player's current job (example)
--- @return table payload { name: string, grade?: number }
function Medal.GV.Ore.job()
  --//=-- Build your payload from framework exports/resources
  return { name = 'unemployed', grade = 0 }
end
```

2) __Route the ore type__ in `gameVein/assayer/client-assayer.lua` by extending `Medal.GV.Ore.assay()`.

```lua
--//=-- Inside Medal.GV.Ore.assay(req)
if oreType == 'job' then
  return Medal.GV.Ore.job()
end
```

3) __If server data is required__, use the shared Request helpers.

```lua
--//=-- client side (gameVein/ore/client-job.lua)
local pendingResults = {}
RegisterNetEvent('medal:gv:ore:resJob', function(requestId, data)
  pendingResults[requestId] = data
end)

function Medal.GV.Ore.job()
  local requestId = Medal.GV.Request.buildId()
  TriggerServerEvent('medal:gv:ore:reqJob', requestId)
  return Medal.GV.Request.await(pendingResults, requestId, 5000, { name = 'unknown' })
end
```

```lua
--//=-- server side (`gameVein/assayer/server-assayer.lua` or a dedicated server file)
RegisterNetEvent('medal:gv:ore:reqJob', function(requestId)
  local src = source
  --//=-- Collect Job data from the frameworks here
  local job = { name = 'unemployed', grade = 0 }
  TriggerClientEvent('medal:gv:ore:resJob', src, requestId, job)
end)
```

4) __Consume from UI__ using the existing NUI minecart endpoint.

```ts
//=-- NUI/UI side
import { nuiPost } from '@/lib/nui'

const ore = await nuiPost('ws:minecart', { type: 'job' })
```

## Utilities Used

- `lib/shared-request.lua` has:
  - `Medal.GV.Request.buildId()` - to build unique request ids.
  - `Medal.GV.Request.await(pending, requestId, timeoutMs?, defaultValue)` - to wait for a response.
- `gameVein/assayer/server-assayer.lua` - detects the framework via `Medal.GV.Assayer.detectFramework()`.
- `gameVein/shaft/client-minecart.lua` - exposes a NUI callback `ws:minecart`, and `Medal.GV.pushMinecart()`.
- `gameVein/shaft/client-overseer.lua` - contains `Medal.GV.prospectVein()` and `Medal.GV.sealShaft()`, to open and close the WebSocket.
