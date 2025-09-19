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

--- Attempt ESX job resolution
---@param src number
---@return Job
local function getEsxJob(src)
  --//=-- Use safe export to obtain ESX shared object
  local ESXObj = safeExport('es_extended', { 'getSharedObject', 'GetSharedObject' })

  if ESXObj and ESXObj.GetPlayerFromId then
    local xp = nil
    pcall(function() xp = ESXObj.GetPlayerFromId(src) end)
    if xp and type(xp.getJob) == 'function' then
      local j = nil
      pcall(function() j = xp.getJob() end)
      if type(j) == 'table' then
        --//=-- Map ESX getJob() fields to our Job structure
        local id = j.id or j.name or 'unknown'
        local name = j.label or j.name or 'unknown'
        local rank = tonumber(j.grade) or -1
        local rankName = j.grade_name or j.grade_label or 'unknown'
        --//=-- Debug: log mapped ESX job
        if type(Logger) == 'table' and type(Logger.debug) == 'function' then
          pcall(Logger.debug, '[GV.Ore.server-job]', { src = src, framework = 'esx', mapped = { id = id, name = name, rank = rank, rankName = rankName }, raw = j })
        end
        return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
      end
    end
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
