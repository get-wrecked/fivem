--//=-- GameVein Assayer: Framework detection utilities, and ore routing
--//=-- This module attempts to determine which FiveM framework is running on the server.

GameVein = GameVein or {}

---@alias FrameworkKey 'qbx'|'qb'|'esx'|'ox'|'nd'|'tmc'|'unknown'

--- Assayer API (server)
---@class GameVeinAssayer
---@field detectFramework fun(forceRefresh?: boolean): FrameworkKey

---@type GameVeinAssayer
GameVein.Assayer = GameVein.Assayer or {}

--- Internal: check if a resource is in the 'started' state
---@param resource string
---@return boolean
local function hasStarted(resource)
    return GetResourceState(resource) == 'started'
end

--- Internal: safe export fetcher (won't error if resource/exports are missing)
--- 
---@param resource string
---@param exportName string
---@return any|nil
local function safeExport(resource, exportName) --//=-- unused
    local ok, result = pcall(function()
        local ex = exports and exports[resource]
        if ex and ex[exportName] then
            return ex[exportName](ex)
        end
        return nil
    end)
    if ok then return result end
    return nil
end

--- QBX detection
--- 
--- Try to detect QBX framework
---@return FrameworkKey|nil
local function detectQBX()
    if hasStarted('qbx_core') then
        return 'qbx'
    end
end

--- QB-Core detection
---
--- Try to detect QB-Core framework
---@return FrameworkKey|nil
local function detectQB()
    if hasStarted('qb-core') then
        return 'qb'
    end
end

--- ESX detection
---
--- Try to detect ESX framework
---@return FrameworkKey|nil
local function detectESX()
    if hasStarted('es_extended') then
        return 'esx'
    end
end

--- OX Core detection
---
--- Try to detect OX Core framework
---@return FrameworkKey|nil
local function detectOX()
    if hasStarted('ox_core') then
        return 'ox'
    end
end

--- ND Core detection
---
--- Try to detect ND Core framework
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
---
--- Try to detect TMC framework
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
--- Search order: QBX -> QB -> ESX -> OX -> ND -> TMC.
---
---@param forceRefresh? boolean Set true to bypass cache and re-check all detectors
---@return FrameworkKey
function GameVein.Assayer.detectFramework(forceRefresh)
    if not forceRefresh and cached ~= nil then
        return cached
    end

    --//=-- Run specific detectors in priority order
    local detectors = { detectESX, detectQB, detectQBX, detectOX, detectND, detectTMC }
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
--- @param reqId string
local function handleReqFrameworkKey(reqId)
    local src = source
    local key = GameVein.Assayer.detectFramework(false)
    --//=-- Respond only to the requesting player
    TriggerClientEvent('gameVein:assayer:resFrameworkKey', src, reqId, key)
end

RegisterNetEvent('gameVein:assayer:reqFrameworkKey')
AddEventHandler('gameVein:assayer:reqFrameworkKey', handleReqFrameworkKey)
