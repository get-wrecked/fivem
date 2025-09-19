--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/ore/server-name.lua
  =====================
  Description:
    GameVein Ore: Player Name (server)
    Resolves ESX character name on the server using safe framework exports.
  ---
  Exports:
    None
  ---
  Globals:
    None
]]

--//=-- Shared helper alias: use Framework service safeExport
---@param ... any
---@return any|nil
local function safeExport(resource, method, ...)
  if Medal and Medal.Services and Medal.Services.Framework and Medal.Services.Framework.safeExport then
    return Medal.Services.Framework.safeExport(resource, method, ...)
  end
  return nil
end

--- Resolve an ESX player's display name using server-side APIs
---@param src number
---@return string
local function getEsxName(src)
  local ESXObj = safeExport('es_extended', { 'getSharedObject', 'GetSharedObject' })
  if ESXObj and type(ESXObj.GetPlayerFromId) == 'function' then
    local xp = nil
    pcall(function() xp = ESXObj.GetPlayerFromId(src) end)
    if xp and type(xp.getName) == 'function' then
      local full = nil
      pcall(function() full = xp.getName() end)
      if type(full) == 'string' and #full > 0 then
        --//=-- Debug: log mapped ESX name
        if type(Logger) == 'table' and type(Logger.debug) == 'function' then
          pcall(Logger.debug, '[GV.Ore.server-name]', { src = src, framework = 'esx', name = full })
        end
        return full
      end
    end
  end
  return 'unknown'
end

--- Server handler: respond with name for ESX (other frameworks handled client-side)
---@param requestId string
local function handleReqName(requestId)
  local src = source
  local key = 'unknown'
  if Medal and Medal.Services and Medal.Services.Framework and Medal.Services.Framework.detectFramework then
    key = Medal.Services.Framework.detectFramework(false)
  end

  local result = 'unknown'
  if key == 'esx' then
    result = getEsxName(src)
  end

  --//=-- Debug: final server response
  if type(Logger) == 'table' and type(Logger.debug) == 'function' then
    pcall(Logger.debug, '[GV.Ore.server-name:response]', { src = src, framework = key, name = result })
  end

  TriggerClientEvent('medal:gv:ore:resName', src, requestId, result)
end

--//=-- Wire request event for name ore
RegisterNetEvent('medal:gv:ore:reqName', handleReqName)
