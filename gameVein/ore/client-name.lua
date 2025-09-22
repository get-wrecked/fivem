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

--//=-- Cached ox_core active character/groups
---@class OxCharacter
---@field charId number
---@field stateId number
---@field firstname string|nil
---@field lastname string|nil
---@field firstName string|nil
---@field lastName string|nil
---@field gender string|nil
---@field x number|nil
---@field y number|nil
---@field z number|nil
---@field lastPlayed string|nil
---@field health number|nil
---@field armour number|nil
---@field isNew boolean|nil

local oxActiveCharacter ---@type OxCharacter|nil
local oxActiveGroups ---@type table<string, number>|nil

--//=-- Listen for active character selection from ox_core
RegisterNetEvent('ox:setActiveCharacter', function(character, groups)
  oxActiveCharacter = character
  oxActiveGroups = groups
  local f = character and (character.firstName or character.firstname) or ''
  local l = character and (character.lastName or character.lastname) or ''
  logDebug('ox:setActiveCharacter cached', f, l)
end)

--//=-- Cached ND active character
---@class NdCharacter
---@field id number
---@field source number
---@field identifier string
---@field firstname string|nil
---@field lastname string|nil
---@field fullname string|nil
---@field job string|nil
---@field jobInfo table|nil
---@field rank number|nil
---@field rankName string|nil
---@field groups table|nil

local ndActiveCharacter ---@type NdCharacter|nil

--//=-- Listen for ND character loaded
AddEventHandler('ND:characterLoaded', function(character)
  ndActiveCharacter = character
  local f = character and character.firstname or ''
  local l = character and character.lastname or ''
  logDebug('ND:characterLoaded cached', f, l)
end)

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

--//=-- Pending results for ESX name requests
---@type table<string, string>
local pendingNameResults = {}

--//=-- Receive server-resolved ESX name
RegisterNetEvent('medal:gv:ore:resName', function(requestId, value)
  pendingNameResults[requestId] = value
end)

--- Request ESX name from server and wait for response
--- @param timeoutMs? integer
--- @return string
local function requestServerEsxName(timeoutMs)
  local reqId = (Medal and Medal.GV and Medal.GV.Request and Medal.GV.Request.buildId and Medal.GV.Request.buildId()) or tostring(math.random(100000, 999999))
  TriggerServerEvent('medal:gv:ore:reqName', reqId)
  logDebug('esx: requested server name', reqId)

  local result = nil
  if Medal and Medal.GV and Medal.GV.Request and Medal.GV.Request.await then
    result = Medal.GV.Request.await(pendingNameResults, reqId, timeoutMs or 5000, 'unknown')
  else
    --//=-- Simple local await loop fallback
    local started = GetGameTimer()
    local timeout = (timeoutMs or 5000)
    while (GetGameTimer() - started) < timeout do
      local val = pendingNameResults[reqId]
      if val ~= nil then result = val; break end
      Wait(0)
    end
    result = result or 'unknown'
  end

  logDebug('esx: server returned name', result)
  if type(result) == 'string' and #result > 0 then
    return result
  end
  return 'unknown'
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
    --//=-- ESX is resolved server-side to avoid client-side API differences; request and await
    name = requestServerEsxName(5000)
    logDebug('esx: derived name (server)', name)
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      pcall(Logger.debug, '[GV.Ore.name]', { framework = 'esx', name = name })
    end
  
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
      logDebug('qb/qbx: using PlayerData.charinfo firstname/lastname', name)
    elseif PlayerData and PlayerData.firstname and PlayerData.lastname then
      --//=-- Root firstname/lastname variant
      name = ('%s %s'):format(PlayerData.firstname, PlayerData.lastname)
      logDebug('qb/qbx: using PlayerData.firstname/lastname', name)
    elseif PlayerData and PlayerData.firstName and PlayerData.lastName then
      name = ('%s %s'):format(PlayerData.firstName, PlayerData.lastName)
      logDebug('qb/qbx: using PlayerData.firstName/lastName', name)
    elseif PlayerData and type(PlayerData.name) == 'string' and #PlayerData.name > 0 then
      name = tostring(PlayerData.name)
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
          logDebug('qb/qbx: using QBCore.PlayerData.charinfo firstname/lastname', name)
        elseif pd.firstname and pd.lastname then
          name = ('%s %s'):format(pd.firstname, pd.lastname)
          logDebug('qb/qbx: using QBCore.PlayerData firstname/lastname', name)
        elseif pd.firstName and pd.lastName then
          name = ('%s %s'):format(pd.firstName, pd.lastName)
          logDebug('qb/qbx: using QBCore.PlayerData firstName/lastName', name)
        elseif type(pd.name) == 'string' and #pd.name > 0 then
          name = tostring(pd.name)
          logDebug('qb/qbx: using QBCore.PlayerData.name', name)
        end
      end
    end
    logDebug('qb/qbx: derived name', name)
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      pcall(Logger.debug, '[GV.Ore.name]', { framework = frameworkKey, name = name })
    end
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
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      pcall(Logger.debug, '[GV.Ore.name]', { framework = 'tmc', name = name })
    end
  elseif frameworkKey == 'nd' then
    --//=-- Prefer cached ND character from ND:characterLoaded event
    if ndActiveCharacter then
      if type(ndActiveCharacter.fullname) == 'string' and #ndActiveCharacter.fullname > 0 then
        name = ndActiveCharacter.fullname
        logDebug('nd: using cached fullname', name)
      else
        local fn = ndActiveCharacter.firstname
        local ln = ndActiveCharacter.lastname
        if type(fn) == 'string' and #fn > 0 and type(ln) == 'string' and #ln > 0 then
          name = ('%s %s'):format(fn, ln)
          logDebug('nd: using cached firstname/lastname', name)
        end
      end
    end
    logDebug('nd: derived name', name)
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      pcall(Logger.debug, '[GV.Ore.name]', { framework = 'nd', name = name })
    end
  elseif frameworkKey == 'ox' then
    --//=-- Use only cached character from ox:setActiveCharacter; ox exports are unreliable for names
    if oxActiveCharacter then
      local fn = oxActiveCharacter.firstName or oxActiveCharacter.firstname
      local ln = oxActiveCharacter.lastName or oxActiveCharacter.lastname
      if type(fn) == 'string' and #fn > 0 and type(ln) == 'string' and #ln > 0 then
        name = ('%s %s'):format(fn, ln)
        logDebug('ox: using cached active character first/last', name)
      end
    end
    logDebug('ox: derived name', name)
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      pcall(Logger.debug, '[GV.Ore.name]', { framework = 'ox', name = name })
    end
  end

  logDebug('final character name', name)
  return tostring(name)
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