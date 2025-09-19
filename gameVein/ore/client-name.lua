--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/ore/client-name.lua
  =====================
  Description:
    GameVein Ore: Player Name
    Retrieves the player's name, differing depending on the server's framework
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.GV.Ore.name : Get the current client's player name
]]

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}
Medal.Services = Medal.Services or {}

local frameworkKey = nil --//=-- Cached framework key

--//=-- Safe export loader is provided by services/shared-framework-detection.lua

local LOG_TAG = '[GV.Ore.name]' --//=-- Log tag for this module

--- Safe debug logger that prefers Logger.debug/Logger.Debug and falls back to print
--- @param ... any
local function logDebug(...)
  --//=-- Prefer Logger.debug, then Logger.Debug, then Logger.info; else print
  local fn = nil
  if type(Logger) == 'table' then
    if type(Logger.debug) == 'function' then
      fn = Logger.debug
    elseif type(Logger.Debug) == 'function' then
      fn = Logger.Debug
    elseif type(Logger.info) == 'function' then
      fn = Logger.info
    end
  end

  if fn then
    pcall(fn, LOG_TAG, ...)
  else
    --//=-- Fallback print; avoid crashing if json is missing
    print('[Medal]', LOG_TAG, ...)
  end
end

--- Get the current client's player name
--- @return string The player's name or "unknown"
local function getFivemName()
  local name = GetPlayerName(PlayerId()) --//=-- The current player's name
  if type(name) == 'string' and #name > 0 then
    return name
  else
    return 'unknown'
  end
end

--- Get the current client's character name
--- @return string The player's character name or the fivem name
local function getCharacterName() 
  local name = 'unknown' --//=-- Default for character when not found

  do
    --//=-- Always attempt to resolve; cache only if non-'unknown' to avoid sticky cache
    local key = Medal.Services.Framework.getKey()
    if key and key ~= 'unknown' then
      frameworkKey = key
      logDebug('frameworkKey resolved', frameworkKey)
    else
      --//=-- Keep prior cached value if available; else remain unknown
      logDebug('frameworkKey unresolved; keeping cached or unknown', frameworkKey or 'unknown')
    end
  end

  if frameworkKey == 'esx' then
    local ESX = Medal.Services.Framework.safeExport('es_extended', { 'getSharedObject', 'GetSharedObject' }) or rawget(_G, 'ESX')
    logDebug('esx: ESX object type', type(ESX), 'has GetPlayerData', ESX and type(ESX.GetPlayerData) == 'function')
    if ESX and type(ESX.GetPlayerData) == 'function' then
      local playerData = nil
      pcall(function() playerData = ESX.GetPlayerData() end)
      logDebug('esx: playerData present', playerData ~= nil, 'keys: character?', playerData and (playerData.character ~= nil) or false)
      if playerData then
        if playerData.character and playerData.character.firstname and playerData.character.lastname then
          name = ('%s %s'):format(playerData.character.firstname, playerData.character.lastname)
          logDebug('esx: using character.firstname/lastname', name)
        elseif playerData.firstName and playerData.lastName then
          name = ('%s %s'):format(playerData.firstName, playerData.lastName)
          logDebug('esx: using firstName/lastName', name)
        elseif playerData.name then
          name = tostring(playerData.name)
          logDebug('esx: using name field', name)
        end
      end
    end
    logDebug('esx: derived name', name)
  elseif (frameworkKey == 'qb' or frameworkKey == 'qbx') then
    local core = nil
    if frameworkKey == 'qbx' then
      core = Medal.Services.Framework.safeExport('qbx_core', 'GetCoreObject') or rawget(_G, 'QBCore')
    else
      core = Medal.Services.Framework.safeExport('qb-core', 'GetCoreObject') or rawget(_G, 'QBCore')
    end
    logDebug('qb/qbx: core type', type(core), 'has Functions.GetPlayerData', core and core.Functions and type(core.Functions.GetPlayerData) == 'function')
    if core and core.Functions and type(core.Functions.GetPlayerData) == 'function' then
      local pd = nil
      pcall(function() pd = core.Functions.GetPlayerData() end)
      logDebug('qb/qbx: player data present', pd ~= nil, 'has charinfo', pd and (pd.charinfo ~= nil) or false)
      if pd and pd.charinfo and pd.charinfo.firstname and pd.charinfo.lastname then
        name = ('%s %s'):format(pd.charinfo.firstname, pd.charinfo.lastname)
        logDebug('qb/qbx: using charinfo firstname/lastname', name)
      end
    end
    logDebug('qb/qbx: derived name', name)
  elseif frameworkKey == 'tmc' then
    --//=-- Resolve TMC core from known providers (supports exports.core:getCoreObject())
    local TMC = Medal.Services.Framework.safeExport('core', 'getCoreObject')
    if not TMC then
      local ok, res = pcall(function()
        return exports and exports.core and exports.core.getCoreObject and exports.core:getCoreObject()
      end)
      if ok then TMC = res end
    end

    logDebug('tmc: core object resolved', TMC ~= nil, 'type', type(TMC))

    if TMC and TMC.Functions and type(TMC.Functions.GetFullName) == 'function' then
      local full = nil
      local ok, err = pcall(function()
        full = TMC.Functions.GetFullName()
      end)
      logDebug('tmc: GetFullName() ok?', ok, 'result', full, 'err', ok and 'nil' or tostring(err))
      if type(full) == 'string' and #full > 0 then
        name = full
        logDebug('tmc: using full name', name)
      end
    else
      logDebug('tmc: GetFullName() not available on TMC.Functions')
    end
    logDebug('tmc: derived name', name)
  elseif frameworkKey == 'nd' then
    local src = nil
    pcall(function() src = GetPlayerServerId(PlayerId()) end)
    logDebug('nd: server id resolved', src)
    local NDCore = Medal.Services.Framework.safeExport('nd_core', { 'getCoreObject', 'GetCoreObject' }) or rawget(_G, 'NDCore') or rawget(_G, 'ND')
    logDebug('nd: NDCore type', type(NDCore), 'has getPlayer', NDCore and type(NDCore.getPlayer) == 'function')
    if NDCore and type(NDCore.getPlayer) == 'function' then
      local player = nil
      pcall(function() player = NDCore.getPlayer(src) end)
       logDebug('nd: player present', player ~= nil, 'type', type(player))
      if player and type(player.getData) == 'function' then
        local full = nil
        pcall(function() full = player.getData('fullname') end)
        logDebug('nd: getData("fullname") result', full)
        if type(full) == 'string' and #full > 0 then
          name = full
          logDebug('nd: using fullname', name)
        end
      end
    end
    logDebug('nd: derived name', name)
  elseif frameworkKey == 'ox' then
    local pd = Medal.Services.Framework.safeExport('ox_core', { 'GetPlayerData', 'GetPlayer' })
    logDebug('ox: player data object type', type(pd))
    if pd then
      local ci = pd.charinfo or pd.Character or pd.character or nil
      logDebug('ox: charinfo-like table present', ci ~= nil)
      if ci and ci.firstname and ci.lastname then
        name = ('%s %s'):format(ci.firstname, ci.lastname)
        logDebug('ox: using charinfo firstname/lastname', name)
      elseif pd.name then
        name = tostring(pd.name)
        logDebug('ox: using name field', name)
      end
    end
    logDebug('ox: derived name', name)
  end

  logDebug('final character name', name)
  return name
end

--- Get the current client's player name
---@class PlayerNames
---@field fivem string The player's raw FiveM username
---@field character string The player's framework-specific character name

--- Get the current client's player name
--- @return PlayerNames A table containing the player's FiveM and character names
function Medal.GV.Ore.name()
  return {
    fivem = getFivemName(),
    character = getCharacterName(),
  }
end