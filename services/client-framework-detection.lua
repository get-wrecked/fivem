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

--//=-- Wait and Timeout constants
local FRAMEWORK_REQUEST_TIMEOUT_MS = 5000
local WAIT_INSTANT = 0

--//=-- In-flight results, keyed by request id
local pendingResults = {}

--//=-- Cache the last known non-'unknown' framework key
---@type FrameworkKey|nil
local cachedKey = nil

local LOG_TAG = '[Services.Framework.Client]' --//=-- Log tag

--- Safe debug logger (client); prefers Logger.debug then Logger.info
--- @param ... any
local function cLogDebug(...)
  local fn = nil
  if type(Logger) == 'table' then
    if type(Logger.debug) == 'function' then fn = Logger.debug
    elseif type(Logger.info) == 'function' then fn = Logger.info end
  end
  if fn then
    pcall(fn, LOG_TAG, ...)
  else
    print('[Medal]', LOG_TAG, ...)
  end
end

--//=-- Receive framework key response for a given request id
RegisterNetEvent('medal:services:framework:resKey', function(reqId, key)
  pendingResults[reqId] = key
  --//=-- Opportunistically cache non-unknown keys for future calls
  if key and key ~= 'unknown' then
    cachedKey = key
  end
end)

--- Request the server framework key and wait for a response
--- @param timeoutMs? integer Optional timeout in milliseconds (default FRAMEWORK_REQUEST_TIMEOUT_MS)
--- @return FrameworkKey key The detected framework key, or 'unknown' on timeout
function Medal.Services.Framework.getKey(timeoutMs)
  --//=-- Return cached non-unknown immediately
  if cachedKey and cachedKey ~= 'unknown' then
    cLogDebug('getKey: returning cached', cachedKey)
    return cachedKey
  end

  local reqId = Medal.GV and Medal.GV.Request and Medal.GV.Request.buildId and Medal.GV.Request.buildId() or tostring(math.random(100000, 999999))
  --//=-- Send request to server
  TriggerServerEvent('medal:services:framework:reqKey', reqId)
  cLogDebug('getKey: sent request to server', reqId)

  --//=-- Await response with timeout, using shared request helper when available
  local key = nil
  if Medal and Medal.GV and Medal.GV.Request and Medal.GV.Request.await then
    key = Medal.GV.Request.await(pendingResults, reqId, timeoutMs or FRAMEWORK_REQUEST_TIMEOUT_MS, 'unknown')
  else
    --//=-- Fallback simple await if shared helper not present
    local started = GetGameTimer()
    local timeout = (timeoutMs or FRAMEWORK_REQUEST_TIMEOUT_MS)
    while (GetGameTimer() - started) < timeout do
      local val = pendingResults[reqId]
      if val ~= nil then key = val; break end
      Wait(WAIT_INSTANT)
    end
    key = key or 'unknown'
  end

  cLogDebug('getKey: server returned', key)
  if key and key ~= 'unknown' then
    cachedKey = key
    cLogDebug('getKey: caching server key', cachedKey)
    return key
  end

  cLogDebug('getKey: returning unknown')
  return 'unknown'
end
