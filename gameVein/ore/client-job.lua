--//=-- GameVein Ore: Job (client)
--//=-- Retrieves the player's job details via a server-backed request/await pattern.

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

---@type table<string, Job>
local pendingResults = {}

---@param requestId string
---@param data Job
RegisterNetEvent('medal:gv:ore:resJob', function(requestId, data)
  pendingResults[requestId] = data
end)

--//=-- Helpers

--- Build a default/unknown job payload
---@return Job
local function unknownJob()
  return { id = 'unknown', name = 'unknown', rank = -1, rankName = 'unknown' }
end

---@param resource string
---@param method string|string[]
---@param ... any
---@return any|nil
local function safeExport(resource, method, ...)
  if not resource or not exports then return nil end
  local ex = exports[resource]
  if not ex then return nil end
  local methods = type(method) == 'table' and method or { method }
  local args = { ... }
  for _, name in ipairs(methods) do
    local ok, res = pcall(function()
      local fn = ex and ex[name]
      if type(fn) == 'function' then
        return fn(ex, table.unpack(args))
      end
      return nil
    end)
    if ok and res ~= nil then return res end
  end
  return nil
end

--//=-- Client-side resolvers per framework

--- Resolve job using QBCore/QBX client API (Functions.GetPlayerData)
---@param key 'qb'|'qbx'
---@return Job
local function getQbJobClient(key)
  local core = nil
  if key == 'qbx' then
    core = safeExport('qbx_core', 'GetCoreObject') or rawget(_G, 'QBCore')
  else
    core = safeExport('qb-core', 'GetCoreObject') or rawget(_G, 'QBCore')
  end
  if core and core.Functions and type(core.Functions.GetPlayerData) == 'function' then
    local pd = nil
    pcall(function() pd = core.Functions.GetPlayerData() end)
    local jd = pd and pd.job or nil
    if jd then
      local id = jd.id or jd.name or 'unknown'
      local name = jd.label or jd.name or 'unknown'
      local rank = -1
      local rankName = 'unknown'
      if type(jd.grade) == 'table' then
        rank = tonumber(jd.grade.level or jd.grade.grade or jd.grade) or -1
        rankName = jd.grade.name or jd.grade.label or 'unknown'
      else
        rank = tonumber(jd.grade) or -1
      end
      return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
    end
  end
  return unknownJob()
end

--- Resolve job using ND statebag (LocalPlayer.state.job or nd_job)
---@return Job
local function getNdJobClient()
  local lp = rawget(_G, 'LocalPlayer')
  local sb = lp and lp.state or nil
  local jd = sb and (sb.job or sb.nd_job) or nil
  if type(jd) == 'table' then
    local id = jd.id or jd.name or 'unknown'
    local name = jd.label or jd.name or 'unknown'
    local rank = tonumber(jd.grade or (jd.grade and jd.grade.level)) or -1
    local rankName = (jd.grade and (jd.grade.name or jd.grade.label)) or jd.grade_label or jd.grade_name or 'unknown'
    return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
  end
  return unknownJob()
end

--- Resolve job from the  ox_core groups statebag
---@return Job
local function getOxJobClient()
  local lp = rawget(_G, 'LocalPlayer')
  local sb = lp and lp.state or nil
  local groups = sb and (sb.groups or sb.group or sb.ox_groups) or nil
  local group = nil
  if type(groups) == 'table' then
    group = groups.job or groups['job']
    if not group then
      for k, v in pairs(groups) do
        if type(v) == 'table' and (v.type == 'job' or k == 'job' or v.name == 'job') then
          group = v
          break
        end
      end
    end
  end
  if group then
    local id = group.id or group.name or 'unknown'
    local name = group.label or group.name or 'unknown'
    local rank = tonumber(group.grade or (group.grade and group.grade.level)) or -1
    local rankName = group.grade_name or group.grade_label or group.gradeName or group.gradeLabel or 'unknown'
    return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
  end
  return unknownJob()
end

--- Gets the job from the TMC jobs statebag; prefers `onduty=true`
---@return Job
local function getTmcJobClient()
  --//=-- TMC: gets the job from LocalPlayer.state.jobs (player's statebag), using the `onduty` flag
  local lp = rawget(_G, 'LocalPlayer')
  local sb = lp and lp.state or nil
  local jobs = sb and sb.jobs or nil
  if type(jobs) == 'table' and #jobs > 0 then
    local chosen = nil
    for i = 1, #jobs do
      local j = jobs[i]
      if type(j) == 'table' and j.onduty then
        chosen = j
        break
      end
    end
    if chosen then
      local id = chosen.id or chosen.name or 'unknown'
      local name = chosen.label or chosen.name or 'unknown'
      local rank = tonumber(chosen.grade and chosen.grade.level) or -1
      local rankName = (chosen.grade and (chosen.grade.name or chosen.grade.label)) or 'unknown'
      return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
    end
  end
  return unknownJob()
end

--- Request job data from server (ESX supported server-side)
--- @param timeoutMs? integer
--- @return Job
local function requestServerJob(timeoutMs)
  local requestId = Medal.GV.Request.buildId()
  TriggerServerEvent('medal:gv:ore:reqJob', requestId)
  return Medal.GV.Request.await(pendingResults, requestId, timeoutMs or 5000, unknownJob())
end

---Get the player's job information
---@return Job
function Medal.GV.Ore.job()
  --//=-- Resolution order (client-first): TMC -> QB -> QBX -> ND -> OX -> server fallback (ESX)
  do
    local j = getTmcJobClient()
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then return j end
  end
  do
    local j = getQbJobClient('qb')
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then return j end
  end
  do
    local j = getQbJobClient('qbx')
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then return j end
  end
  do
    local j = getNdJobClient()
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then return j end
  end
  do
    local j = getOxJobClient()
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then return j end
  end

  return requestServerJob(5000)
end
