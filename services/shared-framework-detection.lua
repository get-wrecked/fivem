--[[
  Medal.tv - FiveM Resource
  =========================
  File: services/shared-framework-detection.lua
  =====================
  Description:
    Shared framework helpers (client + server)
    Exposes a safe export helper for calling framework exports safely in any runtime.
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.Services.Framework.safeExport : Safely calls an export if available (client+server)
]]


Medal = Medal or {}
Medal.Services = Medal.Services or {}
Medal.Services.Framework = Medal.Services.Framework or {}

local LOG_TAG = '[Services.Framework.Shared]' --//=-- Log tag

--- Safe debug logger; prefers Logger.debug then Logger.info
--- @param ... any
local function sfLogDebug(...)
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

--//=-- Internal: check resource state if available in this runtime
---@param resource string
---@return boolean
local function isResourceStarted(resource)
  --//=-- Server provides GetResourceState; clients typically do not
  local ok, state = pcall(function()
    if type(GetResourceState) == 'function' then
      return GetResourceState(resource)
    end
    return nil
  end)
  return ok and state == 'started'
end

--//=-- Client+Server safe export helper
--- Safely calls an export from a resource.
--- On server, it will only call if the resource is started. On client, it checks exports[resource].
---@param resource string
---@param method string|string[]
---@param ... any
---@return any|nil
function Medal.Services.Framework.safeExport(resource, method, ...)
  if not resource or not exports then return nil end
  --//=-- If GetResourceState is available (server), require started; otherwise continue (client)
  if type(GetResourceState) == 'function' and (not isResourceStarted(resource)) then return nil end

  local ex = exports[resource]
  if not ex then return nil end

  local methods = type(method) == 'table' and method or { method }
  local args = { ... }
  for _, name in ipairs(methods) do
    local ok, result = pcall(function()
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

--//=-- Client: quick check if an export table exists for the resource
---@param resource string
---@return boolean
local function hasExport(resource)
  return type(exports) == 'table' and exports[resource] ~= nil
end

--- Attempt to detect framework from the client side using exports and globals
--- Search order mirrors server: ESX -> QB -> QBX -> ND -> OX -> TMC
--- @return FrameworkKey
function Medal.Services.Framework.detectClient()
  --//=-- ESX: require global or callable client export
  do
    local gl = rawget(_G, 'ESX') ~= nil
    local ex = Medal.Services.Framework.safeExport('es_extended', { 'getSharedObject', 'GetSharedObject' }) ~= nil
    sfLogDebug('detectClient: ESX global', gl, 'export callable', ex)
    if gl or ex then return 'esx' end
  end

  --//=-- QB
  do
    local ex = Medal.Services.Framework.safeExport('qb-core', 'GetCoreObject') ~= nil
    local gl = rawget(_G, 'QBCore') ~= nil
    sfLogDebug('detectClient: QB qb-core export callable', ex, 'global QBCore', gl)
    if ex or gl then return 'qb' end
  end

  --//=-- QBX
  do
    local ex = Medal.Services.Framework.safeExport('qbx_core', 'GetCoreObject') ~= nil
    sfLogDebug('detectClient: QBX qbx_core export callable', ex)
    if ex then return 'qbx' end
  end

  --//=-- ND
  do
    local gl = (rawget(_G, 'NDCore') ~= nil) or (rawget(_G, 'ND') ~= nil)
    local ex = Medal.Services.Framework.safeExport('nd_core', { 'getCoreObject', 'GetCoreObject' }) ~= nil
    sfLogDebug('detectClient: ND global', gl, 'export callable', ex)
    if gl or ex then return 'nd' end
  end

  --//=-- OX
  do
    local ex = Medal.Services.Framework.safeExport('ox_core', { 'GetPlayerData', 'GetPlayer' }) ~= nil
    sfLogDebug('detectClient: OX export callable', ex)
    if ex then return 'ox' end
  end

  --//=-- TMC
  do
    local gl = rawget(_G, 'TMC') ~= nil
    local exDirect = Medal.Services.Framework.safeExport('TMC', { 'GetCoreObject', 'GetCore' }) ~= nil
    sfLogDebug('detectClient: TMC global', gl, 'export callable (TMC)', exDirect)
    if gl or exDirect then return 'tmc' end

    --=-- Scan exports for resources that look like TMC (tmc_*/tmc-*, any case) and try known methods
    local foundCallable = false
    if type(exports) == 'table' then
      local patterns = { '^[Tt][Mm][Cc][_].+', '^[Tt][Mm][Cc][%-].+' }
      for res, _ in pairs(exports) do
        local matches = false
        for i = 1, #patterns do
          if type(res) == 'string' and res:match(patterns[i]) then matches = true; break end
        end
        if matches then
          local callable = Medal.Services.Framework.safeExport(res, { 'GetCoreObject', 'GetCore' }) ~= nil
          sfLogDebug('detectClient: TMC candidate export', res, 'callable', callable)
          if callable then
            foundCallable = true
            break
          end
        end
      end
    end
    if foundCallable then return 'tmc' end
  end

  sfLogDebug('detectClient: no framework matched; returning unknown')
  return 'unknown'
end
