--[[
  Medal.tv - FiveM Resource
  =========================
  File: services/server-framework-detection.lua
  =====================
  Description:
    Framework detection service (server)
    Provides detection of the active framework and safe export invocation.
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.Services.Framework.detectFramework : Detects which framework is active
    - Medal.Services.Framework.safeExport : Safely calls an export if available
]]


Medal = Medal or {}
Medal.Services = Medal.Services or {}

---@class FrameworkService
---@field detectFramework fun(forceRefresh?: boolean): FrameworkKey
---@field safeExport fun(resource: string, method: string|string[], ...): any|nil
Medal.Services.Framework = Medal.Services.Framework or {}

--- Internal: check if a resource is in the 'started' state
---@param resource string
---@return boolean
local function hasStarted(resource)
  --//=-- Uses fxserver native to check resource state
  return GetResourceState(resource) == 'started'
end

--- Internal: safe export fetcher/invoker (won't error if resource/exports are missing)
---@param resource string
---@param method string|string[]
---@param ... any
---@return any|nil
function Medal.Services.Framework.safeExport(resource, method, ...)
  if not resource or not hasStarted(resource) then return nil end
  local methods = type(method) == 'table' and method or { method }
  local args = { ... }
  for _, name in ipairs(methods) do
    local ok, result = pcall(function()
      local ex = exports and exports[resource]
      local fn = ex and ex[name]
      if type(fn) == 'function' then
        --//=-- Call with explicit self to support ':' style exports
        return fn(ex, table.unpack(args))
      end
      return nil
    end)
    if ok and result ~= nil then return result end
  end
  return nil
end

--//=-- Individual framework detectors

--- QBX detection
---@return FrameworkKey|nil
local function detectQBX()
  if hasStarted('qbx_core') then
    return 'qbx'
  end
end

--- QB-Core detection
---@return FrameworkKey|nil
local function detectQB()
  if hasStarted('qb-core') then
    return 'qb'
  end
end

--- ESX detection
---@return FrameworkKey|nil
local function detectESX()
  if hasStarted('es_extended') then
    return 'esx'
  end
end

--- OX Core detection
---@return FrameworkKey|nil
local function detectOX()
  if hasStarted('ox_core') then
    return 'ox'
  end
end

--- ND Core detection
---@return FrameworkKey|nil
local function detectND()
  local ndResources = { 'ND_Core', 'nd-core', 'nd_core' }
  for _, res in ipairs(ndResources) do
    if hasStarted(res) then
      return 'nd'
    end
  end
end

--- TMC detection
---@return FrameworkKey|nil
local function detectTMC()
  local tmcResources = { 'tmc-core', 'tmc_core', 'tmc-base', 'tmc_base', 'tmc' }
  for _, res in ipairs(tmcResources) do
    if hasStarted(res) then
      return 'tmc'
    end
  end
end

--- Cached result to avoid repeated checks
---@type FrameworkKey|nil
local cached

--- Detect the active framework on the server.
--- If multiple frameworks are present, the first match in the search order wins.
--- Search order: ESX -> QB -> QBX -> ND -> OX -> TMC.
---@param forceRefresh? boolean Set true to bypass cache and re-check all detectors
---@return FrameworkKey
function Medal.Services.Framework.detectFramework(forceRefresh)
  if not forceRefresh and cached ~= nil then
    return cached
  end

  --//=-- Run specific detectors in priority order
  local detectors = { detectESX, detectQB, detectQBX, detectND, detectOX, detectTMC }
  for _, fn in ipairs(detectors) do
    local ok, res = pcall(fn)
    if ok and res ~= nil then
      --//=-- Key is returned directly by detectors
      cached = res
      return cached
    end
  end

  --//=-- No known framework detected
  cached = 'unknown'
  return cached
end

--- Server-side handler for client requests of the framework key
---@param reqId string
local function handleReqFrameworkKey(reqId)
  local src = source
  local key = Medal.Services.Framework.detectFramework(false)
  --//=-- Respond only to the requesting player
  TriggerClientEvent('medal:services:framework:resKey', src, reqId, key)
end

--//=-- Wire request event for clients
RegisterNetEvent('medal:services:framework:reqKey', handleReqFrameworkKey)
