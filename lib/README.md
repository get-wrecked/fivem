# lib

Shared utilities; used by GameVein, and other modules.

## Files

- `client-cache.lua`
  - A lightweight cache of for constantly retrieved values (ex:`player`, `playerSrc`, `ped`).
    - `ped` auto-updates.
  - This exports a `Cache` instance.
- `shared-request.lua`
  - Request/response helpers:
    - `Medal.GV.Request.buildId()`
    - `Medal.GV.Request.await(pending, id, timeoutMs?, default)`
- `client-logger.lua`
  - NUI callback `ws:log` bridging UI logs to the Lua `Logger`.
- `client-main.lua`, `server-main.lua`
  - Placeholders for future shared functions.

## Example: The Await Helper

```lua
--//=-- `pending` is a table (keyed by `requestId`)
local result = Medal.GV.Request.await(pending, requestId, 5000, nil)
```
