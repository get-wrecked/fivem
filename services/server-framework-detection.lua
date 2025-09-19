--[[
  Medal.tv - FiveM Resource
  =========================
  File: services/server-framework-detection.lua
  =====================
  Description:
    Framework detection service (server)
    Provides detection of the active framework.
    (Safe export invocation is provided by `services/shared-framework-detection.lua` now).
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.Services.Framework.detectFramework : Detects which framework is active
]]


Medal = Medal or {}
Medal.Services = Medal.Services or {}

---@class FrameworkService
---@field detectFramework fun(forceRefresh?: boolean): FrameworkKey
Medal.Services.Framework = Medal.Services.Framework or {}

local LOG_TAG = '[Services.Framework.Server]' --//=-- Log tag

--- Safe debug logger on server; prefers Logger.debug then Logger.info
--- @param ... any
local function sLogDebug(...)
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

--- Internal: check if a resource is in the 'started' state
---@param resource string
---@return boolean
local function hasStarted(resource)
  --//=-- Uses fxserver native to check resource state
  return GetResourceState(resource) == 'started'
end

--//=-- Safe export is provided in shared helpers (client + server)

--//=-- Individual framework detectors

--- QBX detection
---@return FrameworkKey|nil
local function detectQBX()
  local started = hasStarted('qbx_core')
  sLogDebug('detectQBX: qbx_core started', started)
  if started then return 'qbx' end
end

--- QB-Core detection
---@return FrameworkKey|nil
local function detectQB()
  local started = hasStarted('qb-core')
  sLogDebug('detectQB: qb-core started', started)
  if started then return 'qb' end
end

--- ESX detection
---@return FrameworkKey|nil
local function detectESX()
  local started = hasStarted('es_extended')
  sLogDebug('detectESX: es_extended started', started)
  if started then return 'esx' end
end

--- OX Core detection
---@return FrameworkKey|nil
local function detectOX()
  local started = hasStarted('ox_core')
  sLogDebug('detectOX: ox_core started', started)
  if started then return 'ox' end
end

--- ND Core detection
---@return FrameworkKey|nil
local function detectND()
  local ndResources = { 'ND_Core', 'nd-core', 'nd_core' }
  for _, res in ipairs(ndResources) do
    local started = hasStarted(res)
    sLogDebug('detectND:', res, 'started', started)
    if started then return 'nd' end
  end
end

--- TMC detection
---@return FrameworkKey|nil
local function detectTMC()
  --//=-- First check a small set of common names quickly
  local tmcResources = {
    'tmc', 'TMC',
    'tmc-core', 'tmc_core', 'tmc-base', 'tmc_base', 'tmc_queue',
    'TMC-core', 'TMC_core', 'TMC-base', 'TMC_base', 'TMC_queue'
  }
  for _, res in ipairs(tmcResources) do
    local started = hasStarted(res)
    sLogDebug('detectTMC: quick check', res, 'started', started)
    if started then return 'tmc' end
  end

  --//=-- Then scan all resources for names that look like TMC (tmc_* or tmc-*)
  local num = GetNumResources and GetNumResources() or 0
  for i = 0, (num - 1) do
    local name = GetResourceByFindIndex(i)
    if type(name) == 'string' then
      local looksLikeTmc = name:match('^[Tt][Mm][Cc][_%-].+') ~= nil
      if looksLikeTmc then
        local started = hasStarted(name)
        sLogDebug('detectTMC: scan candidate', name, 'started', started)
        if started then return 'tmc' end
      end
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

  --//=-- Presence-only checks: use resource started state; do not invoke exports
  --//=-- Search order: ESX -> QB -> QBX -> ND -> OX -> TMC

  -- ESX
  if hasStarted('es_extended') then
    cached = 'esx'
    sLogDebug('detectFramework: detected esx')
    return cached
  end

  -- QBX first: qbx_core often 'provides' qb-core; prefer qbx classification
  if hasStarted('qbx_core') then
    cached = 'qbx'
    sLogDebug('detectFramework: detected qbx')
    return cached
  end

  -- QB-Core
  if hasStarted('qb-core') then
    cached = 'qb'
    sLogDebug('detectFramework: detected qb')
    return cached
  end

  -- ND (common name variants)
  do
    local ndResources = { 'ND_Core', 'nd-core', 'nd_core' }
    for _, res in ipairs(ndResources) do
      if hasStarted(res) then
        cached = 'nd'
        sLogDebug('detectFramework: detected nd via', res)
        return cached
      end
    end
  end

  -- OX Core
  if hasStarted('ox_core') then
    cached = 'ox'
    sLogDebug('detectFramework: detected ox')
    return cached
  end

  -- TMC: quick list, then scan for tmc_* or tmc-*
  do
    local tmcResources = {
      'tmc', 'TMC',
      'tmc-core', 'tmc_core', 'tmc-base', 'tmc_base', 'tmc_queue',
      'TMC-core', 'TMC_core', 'TMC-base', 'TMC_base', 'TMC_queue'
    }
    for _, res in ipairs(tmcResources) do
      if hasStarted(res) then
        cached = 'tmc'
        sLogDebug('detectFramework: detected tmc via', res)
        return cached
      end
    end

    local num = GetNumResources and GetNumResources() or 0
    for i = 0, (num - 1) do
      local name = GetResourceByFindIndex(i)
      if type(name) == 'string' then
        local looksLikeTmc = name:match('^[Tt][Mm][Cc][_%-].+') ~= nil
        if looksLikeTmc and hasStarted(name) then
          cached = 'tmc'
          sLogDebug('detectFramework: detected tmc via scan', name)
          return cached
        end
      end
    end
  end

  --//=-- No known framework detected
  cached = 'unknown'
  sLogDebug('detectFramework: no framework detected')
  return cached
end

--- Server-side handler for client requests of the framework key
---@param reqId string
local function handleReqFrameworkKey(reqId)
  local src = source
  --//=-- Force refresh each request to avoid stale cached value when resources change
  local key = Medal.Services.Framework.detectFramework(true)
  sLogDebug('handleReqFrameworkKey: src', src, 'reqId', reqId, 'key', key)
  --//=-- Respond only to the requesting player
  TriggerClientEvent('medal:services:framework:resKey', src, reqId, key)
end

--//=-- Wire request event for clients
RegisterNetEvent('medal:services:framework:reqKey', handleReqFrameworkKey)
