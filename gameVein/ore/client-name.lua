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

---@class QbCharInfo
---@field firstname string
---@field lastname string

---@class QbPlayerData
---@field charinfo QbCharInfo|nil
---@field firstname string|nil
---@field lastname string|nil
---@field firstName string|nil
---@field lastName string|nil
---@field name string|nil

---@class QBCoreLike
---@field PlayerData QbPlayerData|nil

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
    --//=-- Use safe export to get PlayerData directly from framework export
    ---@type QbPlayerData|function|nil
    local PlayerData = nil
    if frameworkKey == 'qbx' then
      pcall(function() PlayerData = Medal.Services.Framework.safeExport('qbx_core', 'GetPlayerData') end)
    else
      pcall(function() PlayerData = Medal.Services.Framework.safeExport('qb-core', 'GetPlayerData') end)
    end
    --//=-- If the export returns a function, invoke it to get the table
    if type(PlayerData) == 'function' then
      local ok, res = pcall(PlayerData)
      if ok then PlayerData = res end
    end
    if type(PlayerData) == 'table' then
      ---@cast PlayerData QbPlayerData
    else
      PlayerData = nil
    end
    logDebug('qb/qbx: PlayerData type', type(PlayerData))
    if PlayerData and PlayerData.charinfo and PlayerData.charinfo.firstname and PlayerData.charinfo.lastname then
      name = ('%s %s'):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname)
      print('Full name: ' .. PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname) --//=-- Requested debug print
      logDebug('qb/qbx: using PlayerData.charinfo firstname/lastname', name)
    elseif PlayerData and PlayerData.firstname and PlayerData.lastname then
      --//=-- Root firstname/lastname variant
      name = ('%s %s'):format(PlayerData.firstname, PlayerData.lastname)
      print('Full name: ' .. PlayerData.firstname .. ' ' .. PlayerData.lastname)
      logDebug('qb/qbx: using PlayerData.firstname/lastname', name)
    elseif PlayerData and PlayerData.firstName and PlayerData.lastName then
      name = ('%s %s'):format(PlayerData.firstName, PlayerData.lastName)
      print('Full name: ' .. PlayerData.firstName .. ' ' .. PlayerData.lastName)
      logDebug('qb/qbx: using PlayerData.firstName/lastName', name)
    elseif PlayerData and type(PlayerData.name) == 'string' and #PlayerData.name > 0 then
      name = tostring(PlayerData.name)
      print('Full name: ' .. name)
      logDebug('qb/qbx: using PlayerData.name', name)
    else
      --//=-- Fallback: get core object and try QBCore.PlayerData.charinfo
      ---@type QBCoreLike|nil
      local QBCore = nil
      if frameworkKey == 'qbx' then
        pcall(function() QBCore = Medal.Services.Framework.safeExport('qbx_core', 'GetCoreObject') end)
      else
        pcall(function() QBCore = Medal.Services.Framework.safeExport('qb-core', 'GetCoreObject') end)
      end
      if QBCore and type(QBCore) == 'table' and type(QBCore.PlayerData) == 'table' then
        ---@type QbPlayerData
        local pd = QBCore.PlayerData
        if pd.charinfo and pd.charinfo.firstname and pd.charinfo.lastname then
          name = ('%s %s'):format(pd.charinfo.firstname, pd.charinfo.lastname)
          print('Full name: ' .. pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname)
          logDebug('qb/qbx: using QBCore.PlayerData.charinfo firstname/lastname', name)
        elseif pd.firstname and pd.lastname then
          name = ('%s %s'):format(pd.firstname, pd.lastname)
          print('Full name: ' .. pd.firstname .. ' ' .. pd.lastname)
          logDebug('qb/qbx: using QBCore.PlayerData firstname/lastname', name)
        elseif pd.firstName and pd.lastName then
          name = ('%s %s'):format(pd.firstName, pd.lastName)
          print('Full name: ' .. pd.firstName .. ' ' .. pd.lastName)
          logDebug('qb/qbx: using QBCore.PlayerData firstName/lastName', name)
        elseif type(pd.name) == 'string' and #pd.name > 0 then
          name = tostring(pd.name)
          print('Full name: ' .. name)
          logDebug('qb/qbx: using QBCore.PlayerData.name', name)
        end
      end
    end
    logDebug('qb/qbx: derived name', name)
  elseif frameworkKey == 'tmc' then
    --//=-- TMC: derive full name directly from the player's statebag
    local lp = rawget(_G, 'LocalPlayer')
    local st = lp and lp.state or nil
    logDebug('tmc: LocalPlayer/state present', lp ~= nil, st ~= nil)

    if st and st.playerLoaded and st.charinfo then
      local full = nil
      if st.charinfo.overrideFullName and type(st.charinfo.overrideFullName) == 'string' and #st.charinfo.overrideFullName > 0 then
        full = st.charinfo.overrideFullName
        logDebug('tmc: fullname via overrideFullName', full)
      elseif type(st.charinfo.firstname) == 'string' and type(st.charinfo.lastname) == 'string' then
        full = ('%s %s'):format(st.charinfo.firstname, st.charinfo.lastname)
        logDebug('tmc: fullname via firstname/lastname', full)
      end

      if type(full) == 'string' and #full > 0 then
        name = full
        logDebug('tmc: using full name', name)
      end
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