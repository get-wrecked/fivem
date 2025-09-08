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

---Shared helper alias: use Assayer.safeExport
---@param ... any
---@return any|nil
local safeExport = (Medal and Medal.GV and Medal.GV.Assayer and Medal.GV.Assayer.safeExport) or function(...)
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
  local ESXObj = safeExport('es_extended', 'getSharedObject')

  if ESXObj and ESXObj.GetPlayerFromId then
    local xp = nil
    pcall(function() xp = ESXObj.GetPlayerFromId(src) end)
    local j = xp and xp.job or nil
    if j then
      local id = j.id or j.name or 'unknown'
      local name = j.label or j.name or 'unknown'
      local rank = -1
      local rankName = 'unknown'
      if type(j.grade) == 'number' then rank = j.grade end
      if type(j.grade) == 'table' then
        if type(j.grade.level) == 'number' then rank = j.grade.level end
        if type(j.grade.grade) == 'number' then rank = j.grade.grade end
        if type(j.grade.name) == 'string' then rankName = j.grade.name end
        if type(j.grade.label) == 'string' then rankName = j.grade.label end
      end
      if type(j.grade_label) == 'string' then rankName = j.grade_label end
      if type(j.grade_name) == 'string' then rankName = j.grade_name end
      return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
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
  local key = Medal.GV and Medal.GV.Assayer and Medal.GV.Assayer.detectFramework and Medal.GV.Assayer.detectFramework(false) or 'unknown'

  ---@type Job
  local data = unknownJob()
  --//=-- Only ESX is resolved on the server; all others return unknown and should be handled client-side
  if key == 'esx' then
    data = getEsxJob(src)
  else
    data = unknownJob()
  end

  TriggerClientEvent('medal:gv:ore:resJob', src, requestId, data)
end

--//=-- Request/Response wiring for job ore
RegisterNetEvent('medal:gv:ore:reqJob', handleReqJob)
