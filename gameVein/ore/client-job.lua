--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/ore/client-job.lua
  =====================
  Description:
    GameVein Ore: Job (client)
    Retrieves the player's job details via a server-backed request/await pattern.
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.GV.Ore.job : Get the player's job information
]]

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}
Medal.Services = Medal.Services or {}

--//=-- Cached ND active character for job/group resolution
---@class NdCharacterForJob
---@field job string|nil
---@field jobInfo table|nil
---@field groups table<string, table>|nil
local ndActiveCharacter ---@type NdCharacterForJob|nil

--//=-- Listen for ND character load to cache job/groups
--//=-- Ensure ND event is registered
RegisterNetEvent('ND:characterLoaded', function(character)
  ndActiveCharacter = character
  if type(Logger) == 'table' and type(Logger.debug) == 'function' then
    local j = character and character.job or 'nil'
    local gCount = 0
    if character and type(character.groups) == 'table' then for _ in pairs(character.groups) do gCount = gCount + 1 end end
    Logger.debug('[GV.Ore.job]', 'ND:characterLoaded cached', j, 'groups', gCount)
  end
end)

--//=-- Cached ox_core groups from active character selection
---@type table<string, number>|nil
local oxActiveGroups = nil

--//=-- Listen for ox_core active character and cache groups for job resolution
RegisterNetEvent('ox:setActiveCharacter', function(character, groups)
  oxActiveGroups = groups
  if type(Logger) == 'table' and type(Logger.debug) == 'function' then
    local count = 0
    if type(groups) == 'table' then for _ in pairs(groups) do count = count + 1 end end
    Logger.debug('[GV.Ore.job]', 'ox:setActiveCharacter cached groups', count)
  end
end)

---@class QbJobGrade
---@field name string|nil
---@field label string|nil
---@field level number|nil
---@field grade number|nil

---@class QbJob
---@field id string|nil
---@field name string|nil
---@field label string|nil
---@field payment number|nil
---@field onDuty boolean|nil
---@field isBoss boolean|nil
---@field grade QbJobGrade|number|nil

---@class QbPlayerDataForJob
---@field job QbJob|nil

---@type table<string, Job>
local pendingResults = {}

---@param requestId string
---@param data Job
RegisterNetEvent('medal:gv:ore:resJob', function(requestId, data)
  pendingResults[requestId] = data
end)

--- Build a default/unknown job payload
---@return Job
local function unknownJob()
  return { id = 'unknown', name = 'unknown', rank = -1, rankName = 'unknown' }
end

--//=-- Client-side resolvers per framework

--- Resolve job using QBCore/QBX client API (Functions.GetPlayerData)
---@param key 'qb'|'qbx'
---@return Job
local function getQbJobClient(key)
  --//=-- Prefer calling GetPlayerData directly via safe export; some builds return a function
  ---@type QbPlayerDataForJob|function|nil
  local PlayerData = nil
  if key == 'qbx' then
    pcall(function() PlayerData = Medal.Services.Framework.safeExport('qbx_core', 'GetPlayerData') end)
  else
    pcall(function() PlayerData = Medal.Services.Framework.safeExport('qb-core', 'GetPlayerData') end)
  end
  if type(PlayerData) == 'function' then
    local ok, res = pcall(PlayerData)
    if ok then PlayerData = res end
  end
  if type(PlayerData) == 'table' then
    ---@cast PlayerData QbPlayerDataForJob
    local jd = PlayerData.job
    if type(jd) == 'table' then
      local id = jd.id or jd.name or 'unknown'
      local name = jd.label or jd.name or 'unknown'
      local rank = -1
      local rankName = 'unknown'
      if type(jd.grade) == 'table' then
        ---@cast jd QbJob
        rank = tonumber(jd.grade.level or jd.grade.grade) or -1
        rankName = jd.grade.name or jd.grade.label or 'unknown'
      else
        rank = tonumber(jd.grade) or -1
      end
      return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
    end
  end

  --//=-- Fallback: obtain QBCore object and read QBCore.PlayerData.job
  ---@type table|nil
  local QBCore = nil
  if key == 'qbx' then
    pcall(function() QBCore = Medal.Services.Framework.safeExport('qbx_core', 'GetCoreObject') end)
  else
    pcall(function() QBCore = Medal.Services.Framework.safeExport('qb-core', 'GetCoreObject') end)
  end
  if QBCore and type(QBCore) == 'table' and type(QBCore.PlayerData) == 'table' then
    ---@type QbPlayerDataForJob
    local pd = QBCore.PlayerData
    local jd = pd and pd.job or nil
    if type(jd) == 'table' then
      local id = jd.id or jd.name or 'unknown'
      local name = jd.label or jd.name or 'unknown'
      local rank = -1
      local rankName = 'unknown'
      if type(jd.grade) == 'table' then
        rank = tonumber(jd.grade.level or jd.grade.grade) or -1
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
  --//=-- Prefer cached ND character (event-driven)
  if ndActiveCharacter and type(ndActiveCharacter) == 'table' then
    local ch = ndActiveCharacter
    --//=-- Try groups first, find the group flagged as a job
    local groups = ch.groups
    if type(groups) == 'table' then
      local chosenKey, chosen = nil, nil
      for k, v in pairs(groups) do
        if type(v) == 'table' and (v.isJob == true or v.isJob == 1) then
          chosenKey, chosen = k, v
          break
        end
      end
      if not chosen then
        for k, v in pairs(groups) do chosenKey, chosen = k, v; break end
      end
      if chosen then
        local id = chosen.id or chosen.name or chosenKey or 'unknown'
        local name = chosen.label or chosen.name or chosenKey or 'unknown'
        local rank = tonumber(chosen.rank or (chosen.grade and chosen.grade.level)) or -1
        local rankName = chosen.rankName or chosen.rank_label or (chosen.grade and (chosen.grade.name or chosen.grade.label)) or 'unknown'
        return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
      end
    end
    --//=-- Fallback to character.job / character.jobInfo
    if ch.job or ch.jobInfo then
      local id = ch.job or (type(ch.jobInfo) == 'table' and (ch.jobInfo.id or ch.jobInfo.name)) or 'unknown'
      local name = (type(ch.jobInfo) == 'table' and (ch.jobInfo.label or ch.jobInfo.name)) or id or 'unknown'
      local rank = -1
      local rankName = 'unknown'
      if type(ch.jobInfo) == 'table' then
        rank = tonumber(ch.jobInfo.rank or ch.jobInfo.grade) or -1
        rankName = ch.jobInfo.rankName or ch.jobInfo.rank_name or ch.jobInfo.gradeName or ch.jobInfo.grade_label or 'unknown'
      end
      return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
    end
  end
  return unknownJob()
end

--- Resolve job from the  ox_core groups statebag
---@return Job
local function getOxJobClient()
  --//=-- Prefer cached ox groups from event: table<string, number>
  if type(oxActiveGroups) == 'table' then
    local chosenName, chosenRank = nil, nil
    for k, v in pairs(oxActiveGroups) do
      if type(k) == 'string' and type(v) == 'number' then
        if not chosenRank or v > chosenRank then
          chosenName, chosenRank = k, v
        end
      end
    end
    if chosenName then
      local id = chosenName
      local name = chosenName
      local rank = tonumber(chosenRank) or -1
      local rankName = 'unknown'
      return { id = tostring(id), name = tostring(name), rank = rank, rankName = tostring(rankName) }
    end
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
  --//=-- On ESX, resolve on the server to avoid client-side API/shape differences
  do
    local key = Medal and Medal.Services and Medal.Services.Framework and Medal.Services.Framework.getKey and Medal.Services.Framework.getKey() or 'unknown'
    if key == 'esx' then
      local j = requestServerJob(5000)
      if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        Logger.debug('[GV.Ore.job]', { framework = 'esx', job = j })
      end
      return j
    end
  end

  --//=-- Resolution order (client-first): TMC -> QB -> QBX -> ND -> OX -> server fallback (ESX)
  do
    local j = getTmcJobClient()
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then
      if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        Logger.debug('[GV.Ore.job]', { framework = 'tmc', job = j })
      end
      return j
    end
  end
  do
    local j = getQbJobClient('qb')
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then
      if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        Logger.debug('[GV.Ore.job]', { framework = 'qb', job = j })
      end
      return j
    end
  end
  do
    local j = getQbJobClient('qbx')
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then
      if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        Logger.debug('[GV.Ore.job]', { framework = 'qbx', job = j })
      end
      return j
    end
  end
  do
    local j = getNdJobClient()
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then
      if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        Logger.debug('[GV.Ore.job]', { framework = 'nd', job = j })
      end
      return j
    end
  end
  do
    local j = getOxJobClient()
    if j and j.id ~= 'unknown' and j.name ~= 'unknown' then
      if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        Logger.debug('[GV.Ore.job]', { framework = 'ox', job = j })
      end
      return j
    end
  end

  return requestServerJob(5000)
end
