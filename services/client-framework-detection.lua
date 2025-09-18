--[[
  Medal.tv - FiveM Resource
  =========================
  File: services/client-framework-detection.lua
  =====================
  Description:
    Framework detection service (client)
    Exposes an API to request and await the server-detected framework key.
    (Safe export invocation is provided by `services/shared-framework-detection.lua` now).
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.Services.Framework.getKey : Request the server framework key and await response
]]


Medal = Medal or {}
Medal.Services = Medal.Services or {}

---@class FrameworkServiceClient
---@field getKey fun(timeoutMs?: integer): FrameworkKey
Medal.Services.Framework = Medal.Services.Framework or {}

--//=-- In-flight results, keyed by request id
local pendingResults = {}

--//=-- Receive framework key response for a given request id
RegisterNetEvent('medal:services:framework:resKey', function(reqId, key)
  pendingResults[reqId] = key
end)

--- Request the server framework key and wait for a response
--- @param timeoutMs? integer Optional timeout in milliseconds (default 5000)
--- @return FrameworkKey key The detected framework key, or 'unknown' on timeout
function Medal.Services.Framework.getKey(timeoutMs)
  local reqId = Medal.GV and Medal.GV.Request and Medal.GV.Request.buildId and Medal.GV.Request.buildId() or tostring(math.random(100000, 999999))
  --//=-- Send request to server
  TriggerServerEvent('medal:services:framework:reqKey', reqId)

  --//=-- Await response with timeout, using shared request helper when available
  if Medal and Medal.GV and Medal.GV.Request and Medal.GV.Request.await then
    return Medal.GV.Request.await(pendingResults, reqId, timeoutMs or 5000, 'unknown')
  end

  --//=-- Fallback simple await if shared helper not present
  local started = GetGameTimer()
  local timeout = (timeoutMs or 5000)
  while (GetGameTimer() - started) < timeout do
    local val = pendingResults[reqId]
    if val ~= nil then return val end
    Wait(0)
  end
  return 'unknown'
end
