# gameVein/ore

Functions that return discrete pieces of data ("ores").
Each ore is exposed as a function on `Medal.GV.Ore` and may be purely client-side or use a request/response
to communicate with the server.

## Built-in Ores

- __name__ — `Medal.GV.Ore.name()` returns a table `{ fivem, character }` with the player's raw FiveM name and their framework-specific character name.
- __cfxId__ — `Medal.GV.Ore.cfxId()` requests the server's Cfx Id (community identifier) via server event.
- __heartbeat__ — `Medal.GV.Ore.heartbeat()` returns `{ ok, ts, pid }` for round-trip diagnostics.
- __job__ — `Medal.GV.Ore.job()` returns a Job table `{ id, name, rank, rankName }` resolved client-first, with a server fallback for ESX.
- __entityMatrix__ — `Medal.GV.Ore.entityMatrix()` returns an entity matrix `{ right, forward, up, position }` (client).
- __cameraMatrix__ — `Medal.GV.Ore.cameraMatrix()` returns a camera matrix `{ right, forward, up, position }` (client).
- __vehicle__ — `Medal.GV.Ore.vehicle()` returns `{ inVehicle, vehicleInfo }` where `inVehicle` is a boolean indicating if the player is in a vehicle, and `vehicleInfo` is `{ id, name, hash, class, className }` for the current (or last driven) vehicle (client).

See implementations in this folder for reference:
- `client-name.lua`
- `server-name.lua`
- `client-cfx-id.lua`
- `server-cfx-id.lua`
- `client-heartbeat.lua`
- `client-job.lua`
- `server-job.lua`
- `client-entity-matrix.lua`
- `client-camera-matrix.lua`
- `client-vehicle.lua`

## How Ore Routing/Assaying Works

The router in `gameVein/assayer/client-assayer.lua` inspects the request and calls the matching producer:

```lua
--//=-- Inside Medal.GV.Ore.assay(req)
if oreType == 'name' then
  return Medal.GV.Ore.name()
end
if oreType == 'cfxId' then
  return Medal.GV.Ore.cfxId()
end
if oreType == 'heartbeat' then
  return Medal.GV.Ore.heartbeat()
end
if oreType == 'job' then
  return Medal.GV.Ore.job()
end
if oreType == 'entityMatrix' then
  return Medal.GV.Ore.entityMatrix()
end
if oreType == 'cameraMatrix' then
  return Medal.GV.Ore.cameraMatrix()
end

if oreType == 'vehicle' then
  return Medal.GV.Ore.vehicle()
end
```

## Add a New Ore Type

1) __Create a new ore__ in this directory.

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

2) __Route it__ in `gameVein/assayer/client-assayer.lua`:

```lua
--//=-- Inside Medal.GV.Ore.assay(req)
if oreType == 'job' then
  return Medal.GV.Ore.job()
end
```

3) __If server data is required__, use the shared Request helpers from `lib/shared-request.lua`.

Client side pattern:

```lua
--//=-- Client
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

Server side pattern:

```lua
--//=-- Server
RegisterNetEvent('medal:gv:ore:reqJob', function(requestId)
  local src = source
  --//=-- Get job data here, from the various frameworks
  local job = { name = 'unemployed', grade = 0 }
  TriggerClientEvent('medal:gv:ore:resJob', src, requestId, job)
end)
```

4) __Consume from UI__, via the NUI endpoint `ws:minecart`, handled by `gameVein/shaft/client-minecart.lua`:

```ts
// NUI/UI
import { fetchNui } from '@tsfx/hooks';

const ore = await fetchNui('ws:minecart', { payload: { type: 'job' } });
```

## Conventions

- __Function name__: `Medal.GV.Ore.<type>()` where `<type>` is the request `type`.
- __Events__: For server-backed ores use `medal:gv:ore:req<Type>` and `medal:gv:ore:res<Type>`.
- __Timeouts__: Default 5000ms using `Medal.GV.Request.await()`.

## Job Ore Details

- __Resolution order (client)__: TMC statebag → QBCore (qb-core) → QBX (qbx_core) → ND statebag → ox_core groups → server fallback.
- __Server fallback__: Only ESX is resolved on the server. Other frameworks return `unknown` server-side and should be handled by the client resolvers above.
- __Statebag keys used__:
  - TMC: `LocalPlayer.state.jobs` (array), prefers `onduty == true`.
  - ND: `LocalPlayer.state.job` or `LocalPlayer.state.nd_job`.
  - OX: `LocalPlayer.state.groups`/`group`/`ox_groups` and the `'job'` group.
  - QB/QBX: Uses the core's client API `QBCore.Functions.GetPlayerData()` and reads `job`.

The returned shape for all resolvers is normalized to:

```lua
---@class Job
---@field id string
---@field name string
---@field rank integer   -- -1 indicates unknown
---@field rankName string
```
