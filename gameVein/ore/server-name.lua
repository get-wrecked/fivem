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

--- Try to acquire the ESX shared object via multiple strategies
---@return table|nil
local function acquireESX()
  --//=-- Export-only to diagnose import issues precisely
  local obj = safeExport('es_extended', { 'getSharedObject', 'GetSharedObject' })
  return obj
end

--- Resolve an ESX player's display name using server-side APIs
---@param src number
---@return string
local function getEsxName(src)
  --//=-- Export-only acquisition
  local ESXObj = acquireESX()
  if not ESXObj then return 'unknown' end

  --//=-- Resolve xPlayer using ESX.Await when available
  local xPlayer = nil
  if type(ESXObj.Await) == 'function' then
    pcall(function() xPlayer = ESXObj.Await(ESXObj.GetPlayerFromId, src) end)
  else
    pcall(function() xPlayer = ESXObj.GetPlayerFromId and ESXObj.GetPlayerFromId(src) end)
  end
  if not xPlayer then return 'unknown' end

  --//=-- Prefer xPlayer.getName() via Await when available
  local name = nil
  if type(ESXObj.Await) == 'function' and xPlayer.getName ~= nil then
    pcall(function() name = ESXObj.Await(xPlayer.getName) end)
  elseif xPlayer.getName ~= nil then
    pcall(function() name = xPlayer.getName() end)
  end
  if type(name) == 'string' and #name > 0 then
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      pcall(Logger.debug, '[GV.Ore.server-name]', { src = src, source = 'getName', name = name })
    end
    return name
  end

  --//=-- Fallback to xPlayer.get('name') and then firstname/lastname
  if type(ESXObj.Await) == 'function' and xPlayer.get ~= nil then
    pcall(function() name = ESXObj.Await(xPlayer.get, 'name') end)
  elseif xPlayer.get ~= nil then
    pcall(function() name = xPlayer.get('name') end)
  end
  if type(name) == 'string' and #name > 0 then
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      pcall(Logger.debug, '[GV.Ore.server-name]', { src = src, source = "get('name')", name = name })
    end
    return name
  end

  local fn, ln = nil, nil
  if type(ESXObj.Await) == 'function' and xPlayer.get ~= nil then
    pcall(function() fn = ESXObj.Await(xPlayer.get, 'firstname') end)
    pcall(function() ln = ESXObj.Await(xPlayer.get, 'lastname') end)
    if type(fn) ~= 'string' or #fn == 0 then pcall(function() fn = ESXObj.Await(xPlayer.get, 'firstName') end) end
    if type(ln) ~= 'string' or #ln == 0 then pcall(function() ln = ESXObj.Await(xPlayer.get, 'lastName') end) end
  elseif xPlayer.get ~= nil then
    pcall(function() fn = xPlayer.get('firstname') end)
    pcall(function() ln = xPlayer.get('lastname') end)
    if type(fn) ~= 'string' or #fn == 0 then pcall(function() fn = xPlayer.get('firstName') end) end
    if type(ln) ~= 'string' or #ln == 0 then pcall(function() ln = xPlayer.get('lastName') end) end
  end
  if type(fn) == 'string' and #fn > 0 and type(ln) == 'string' and #ln > 0 then
    local full = (fn .. ' ' .. ln)
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      pcall(Logger.debug, '[GV.Ore.server-name]', { src = src, source = "get('firstname'/'lastname')", name = full })
    end
    return full
  end

  return 'unknown'
end

--- Server handler: respond with name for ESX (other frameworks handled client-side)
---@param requestId string
local function handleReqName(requestId)
  local src = source
  --//=-- Assume ESX from the detected framework; focus on export path only
  local key = 'esx'

  local result = getEsxName(src)

  --//=-- Debug: final server response
  if type(Logger) == 'table' and type(Logger.debug) == 'function' then
    pcall(Logger.debug, '[GV.Ore.server-name:response]', { src = src, framework = key, name = result })
  end

  TriggerClientEvent('medal:gv:ore:resName', src, requestId, result)
end

--//=-- Wire request event for name ore
RegisterNetEvent('medal:gv:ore:reqName', handleReqName)
