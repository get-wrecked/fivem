--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/ore/server-job.lua
  =====================
  Description:
    GameVein Ore: Job (server)
    A framework-aware job retriever/resolver, with safe fallbacks
  ---
  Exports:
    None
  ---
  Globals:
    None
]]

---Shared helper alias: use Framework service safeExport
---@param ... any
---@return any|nil
local safeExport = (Medal and Medal.Services and Medal.Services.Framework and Medal.Services.Framework.safeExport) or function(...)
  return nil
end

--- Build a default/unknown job payload
---@return Job
local function unknownJob()
  return { id = 'unknown', name = 'unknown', rank = -1, rankName = 'unknown' }
end

--- Try to acquire the ESX shared object via multiple strategies
---@return table|nil
local function acquireESX()
  --//=-- Export-only to match server-name simplified approach
  local obj = safeExport('es_extended', { 'getSharedObject', 'GetSharedObject' })
  return obj
end

--- Attempt ESX job resolution
---@param src number
---@return Job
local function getEsxJob(src)
  --//=-- Export-only acquisition
  local ESXObj = acquireESX()
  if not ESXObj then return unknownJob() end

  --//=-- Resolve xPlayer using Await when available
  local xPlayer = nil
  if type(ESXObj.Await) == 'function' then
    pcall(function() xPlayer = ESXObj.Await(ESXObj.GetPlayerFromId, src) end)
  else
    pcall(function() xPlayer = ESXObj.GetPlayerFromId and ESXObj.GetPlayerFromId(src) end)
  end
  if not xPlayer then return unknownJob() end

  --//=-- Prefer xPlayer.getJob() via Await when available
  local j = nil
  if type(ESXObj.Await) == 'function' and xPlayer.getJob ~= nil then
    pcall(function() j = ESXObj.Await(xPlayer.getJob) end)
  elseif xPlayer.getJob ~= nil then
    pcall(function() j = xPlayer.getJob() end)
  end
  --//=-- Fallback to xPlayer.get('job') or xPlayer.job
  if type(j) ~= 'table' and xPlayer.get ~= nil then
    if type(ESXObj.Await) == 'function' then
      pcall(function() j = ESXObj.Await(xPlayer.get, 'job') end)
    else
      pcall(function() j = xPlayer.get('job') end)
    end
  end
  if type(j) ~= 'table' and type(xPlayer.job) == 'table' then
    j = xPlayer.job
  end

  if type(j) == 'table' then
    local id = j.id or j.name or 'unknown'
    local name = j.label or j.name or 'unknown'
    local rank = tonumber(j.grade) or -1
    local rankName = j.grade_name or j.grade_label or (j.grade and (j.grade.name or j.grade.label)) or 'unknown'
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      pcall(Logger.debug, '[GV.Ore.server-job]', { src = src, source = 'job', mapped = { id = id, name = name, rank = rank, rankName = rankName } })
    end
    return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
  end

  return unknownJob()
end

--- Handler: respond with job data based on active framework
---@param requestId string
local function handleReqJob(requestId)
  local src = source
  --//=-- Server is authoritative only for ESX; other frameworks should be resolved client-side
  
  ---@type FrameworkKey
  local key = Medal.Services and Medal.Services.Framework and Medal.Services.Framework.detectFramework and Medal.Services.Framework.detectFramework(false) or 'unknown'

  ---@type Job
  local data = unknownJob()
  --//=-- Only ESX is resolved on the server; all others return unknown and should be handled client-side
  if key == 'esx' then
    data = getEsxJob(src)
  else
    data = unknownJob()
  end

  --//=-- Debug: final server response
  if type(Logger) == 'table' and type(Logger.debug) == 'function' then
    pcall(Logger.debug, '[GV.Ore.server-job:response]', { src = src, framework = key, job = data })
  end

  TriggerClientEvent('medal:gv:ore:resJob', src, requestId, data)
end

--//=-- Request/Response wiring for job ore
RegisterNetEvent('medal:gv:ore:reqJob', handleReqJob)
