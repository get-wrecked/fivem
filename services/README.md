# services

Shared services for both client and server.

## Framework Detection Service

Detects which gameplay framework the server is running and exposes small helpers to interact with framework exports safely.

### Files

- `client-framework-detection.lua`
  - Client-side helper to request and await the server-detected framework key.
  - API: `Medal.Services.Framework.getKey(timeoutMs?: number): FrameworkKey`
  - Listens for: `medal:services:framework:resKey`
  - Emits: `medal:services:framework:reqKey`

- `server-framework-detection.lua`
  - Server-side framework detectors and safe export wrapper.
  - API: `Medal.Services.Framework.detectFramework(forceRefresh?: boolean): FrameworkKey`
  - API: `Medal.Services.Framework.safeExport(resource: string, method: string|string[], ...): any|nil`
  - Listens for: `medal:services:framework:reqKey`
  - Emits: `medal:services:framework:resKey`

### Framework keys

`FrameworkKey` is defined in `gameVein/__types.lua` and is one of:

```
'esx' | 'qb' | 'qbx' | 'nd' | 'ox' | 'tmc' | 'unknown'
```

### Detection order

The server checks for known resources in this order (first match wins):

```
ESX -> QB -> QBX -> ND -> OX -> TMC -> unknown
```

### Usage examples

Client: request the framework key and branch behavior.

```lua
-- client
local key = Medal.Services.Framework.getKey(5000)
if key == 'qb' or key == 'qbx' then
  --//=-- QB flavored logic here
end
```

Server: detect and use safeExport to call framework functions.

```lua
-- server
local key = Medal.Services.Framework.detectFramework(false)
if key == 'esx' then
  local ESX = Medal.Services.Framework.safeExport('es_extended', 'getSharedObject')
  --//=-- Use ESX safely if available
end
```

Notes:

- `safeExport` ensures no runtime error if the target resource is missing or not started.
- The detection result is cached server-side until `forceRefresh=true` is passed.
