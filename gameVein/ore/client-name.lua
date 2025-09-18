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

  if not frameworkKey then
    frameworkKey = Medal.Services.Framework.getKey()
  end

  if frameworkKey == 'esx' then
    local ESX = Medal.Services.Framework.safeExport('es_extended', { 'getSharedObject', 'GetSharedObject' }) or rawget(_G, 'ESX')
    if ESX and type(ESX.GetPlayerData) == 'function' then
      local playerData = nil
      pcall(function() playerData = ESX.GetPlayerData() end)
      if playerData then
        if playerData.character and playerData.character.firstname and playerData.character.lastname then
          name = ('%s %s'):format(playerData.character.firstname, playerData.character.lastname)
        elseif playerData.firstName and playerData.lastName then
          name = ('%s %s'):format(playerData.firstName, playerData.lastName)
        elseif playerData.name then
          name = tostring(playerData.name)
        end
      end
    end
  elseif (frameworkKey == 'qb' or frameworkKey == 'qbx') then
    local core = nil
    if frameworkKey == 'qbx' then
      core = Medal.Services.Framework.safeExport('qbx_core', 'GetCoreObject') or rawget(_G, 'QBCore')
    else
      core = Medal.Services.Framework.safeExport('qb-core', 'GetCoreObject') or rawget(_G, 'QBCore')
    end
    if core and core.Functions and type(core.Functions.GetPlayerData) == 'function' then
      local pd = nil
      pcall(function() pd = core.Functions.GetPlayerData() end)
      if pd and pd.charinfo and pd.charinfo.firstname and pd.charinfo.lastname then
        name = ('%s %s'):format(pd.charinfo.firstname, pd.charinfo.lastname)
      end
    end
  elseif frameworkKey == 'tmc' then
    local src = nil
    pcall(function() src = GetPlayerServerId(PlayerId()) end)
    local TMC = Medal.Services.Framework.safeExport('TMC', { 'GetCoreObject', 'GetCore' }) or rawget(_G, 'TMC')
    if TMC and TMC.Functions and type(TMC.Functions.GetPlayer) == 'function' then
      local player = nil
      pcall(function() player = TMC.Functions.GetPlayer(src) end)
      if player and player.Functions and type(player.Functions.GetFullName) == 'function' then
        local full = nil
        pcall(function() full = player.Functions.GetFullName(player) end)
        if type(full) == 'string' and #full > 0 then
          name = full
        end
      end
    end
  elseif frameworkKey == 'nd' then
    local src = nil
    pcall(function() src = GetPlayerServerId(PlayerId()) end)
    local NDCore = Medal.Services.Framework.safeExport('nd_core', { 'getCoreObject', 'GetCoreObject' }) or rawget(_G, 'NDCore') or rawget(_G, 'ND')
    if NDCore and type(NDCore.getPlayer) == 'function' then
      local player = nil
      pcall(function() player = NDCore.getPlayer(src) end)
      if player and type(player.getData) == 'function' then
        local full = nil
        pcall(function() full = player.getData('fullname') end)
        if type(full) == 'string' and #full > 0 then
          name = full
        end
      end
    end
  elseif frameworkKey == 'ox' then
    local pd = Medal.Services.Framework.safeExport('ox_core', { 'GetPlayerData', 'GetPlayer' })
    if pd then
      local ci = pd.charinfo or pd.Character or pd.character or nil
      if ci and ci.firstname and ci.lastname then
        name = ('%s %s'):format(ci.firstname, ci.lastname)
      elseif pd.name then
        name = tostring(pd.name)
      end
    end
  end

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