--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/assayer/client-assayer.lua
  =====================
  Description:
    The Assayer handles the data retrieval of various "ores" (chunks of game data) to pass off in "minecarts".
    Each different "ore" is a different source of data, and thus each "ore" is retrieved in a different way, by a different file.
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.GV.Ore.assay : Assay a requested ore, returning it
]]


Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}
--//=-- Client-side Assayer routes ore requests only (framework detection moved to services)
Medal.GV.Assayer = Medal.GV.Assayer or {}

--//=-- Assayer defaults (override via Config.Assayer if present)
local ASSAYER_DEFAULT_RADIUS = (Config and Config.Assayer and tonumber(Config.Assayer.ProximityRadius)) or 60.0
local ASSAYER_DEFAULT_TIMEOUT_MS = (Config and Config.Assayer and tonumber(Config.Assayer.RequestTimeoutMs)) or 1500

--//=-- Pending table for nearby ore aggregation responses
local _pendingNearby = {}

--//=-- Lazy-initialized, lowercase-keyed dispatch for ore types
--//=-- Each value holds the canonical `type` casing and its function
local _oreDispatch = nil

--//=-- Receive aggregated results from the server for a nearby request
RegisterNetEvent('medal:gv:assayer:resNearby', function(requestId, others, invokerBucket)
  _pendingNearby[requestId] = { others = others or {}, invokerBucket = invokerBucket or 0 }
  --//=-- Debug: record receipt of aggregated nearby results
  if Logger and Logger.debug then
    local count = 0
    if type(others) == 'table' then count = #others end
    Logger.debug('assayer:client:resNearby', { requestId = requestId, count = count, invokerBucket = invokerBucket or 0 })
  end
end)

--//=-- Server asks this client to assay an ore (or bundle) on behalf of a nearby requester
RegisterNetEvent('medal:gv:assayer:reqFromServer', function(invokerId, requestId, payload)
  local data = nil
  if Logger and Logger.debug then
    Logger.debug('assayer:client:reqFromServer', { from = invokerId, requestId = requestId, payload = payload })
  end

  if type(payload) == 'table' and type(payload.types) == 'table' then
    local results = {}
    for _, subType in pairs(payload.types) do
      local r = Medal.GV.Ore.assay(subType)
      if r ~= nil then results[subType] = r end
    end
    data = results
  elseif type(payload) == 'table' and type(payload.ore) == 'string' then
    data = Medal.GV.Ore.assay(payload.ore)
  end

  --//=-- Respond back to server with our result (may be nil if unknown)
  if Logger and Logger.debug then
    local hasData = data ~= nil
    Logger.debug('assayer:client:resToServer', { requestId = requestId, to = invokerId, hasData = hasData })
  end
  TriggerServerEvent('medal:gv:assayer:resFromClient', requestId, invokerId, data)
end)

--- Assay a requested ore, and return the relevant data
--- Accepted forms:
---  - string: Treated as the `type` (e.g., 'name')
---  - table: { type = 'name', ... }
---  - table: { type = 'bundle', types = { 'name', 'job' } }
---  - table: { type = 'job', radius = 60, maxPlayers = 5 }   --//=-- proximity fan-out for a single ore
---  - table: { type = 'bundle', types = { 'name', 'job' }, radius = 60, maxPlayers = 5 } --//=-- proximity fan-out for a bundle
--- @param req string|table
--- @return any|table|nil The data for the requested ore, a table of results for a bundle, or nil if unknown
function Medal.GV.Ore.assay(req)
  local oreType = nil

  if type(req) == 'string' then
    oreType = req
  elseif type(req) == 'table' and type(req.type) == 'string' then
    oreType = req.type
  end

  --//=-- Proximity fan-out must run BEFORE direct returns for single ores
  --//=-- If a request includes `radius`, gather from nearby players too (OneSync Infinity)
  if type(req) == 'table' and ((tonumber(req.radius or 0) or 0) > 0) then
    local radius = tonumber(req.radius or ASSAYER_DEFAULT_RADIUS) or ASSAYER_DEFAULT_RADIUS
    local isBundle = (oreType == 'bundle') or (type(req.types) == 'table')
    local maxPlayers = tonumber(req.max or req.maxPlayers or req.count or 0) or 0
    local timeoutMs = tonumber(req.timeoutMs or ASSAYER_DEFAULT_TIMEOUT_MS) or ASSAYER_DEFAULT_TIMEOUT_MS

    --//=-- Build the invoking player's data (first entry of return value)
    local selfData = nil
    if isBundle then
      local results = {}
      for _, subType in pairs(req.types) do
        local r = Medal.GV.Ore.assay(subType)
        if r ~= nil then results[subType] = r end
      end
      selfData = results
    else
      local targetType = oreType
      if type(targetType) ~= 'string' then
        return { nil, {} }
      end
      selfData = Medal.GV.Ore.assay(targetType)
    end

    --//=-- Ask server to gather from nearby players
    local requestId = Medal.GV.Request.buildId()
    if Logger and Logger.debug then
      Logger.debug('assayer:client:reqNearby', { requestId = requestId, oreType = oreType, radius = radius, isBundle = isBundle, max = maxPlayers, timeoutMs = timeoutMs, types = isBundle and req.types or nil })
    end
    TriggerServerEvent('medal:gv:assayer:reqNearby', requestId, {
      radius = radius,
      types = isBundle and req.types or nil,
      ore = (not isBundle) and oreType or nil,
      timeoutMs = timeoutMs,
      max = maxPlayers,
    })

    --//=-- Await aggregated nearby array of { id, source, name, bucket, data, primary=false }
    local pack = Medal.GV.Request.await(_pendingNearby, requestId, timeoutMs, { others = {}, invokerBucket = 0 })
    local others = (type(pack) == 'table' and type(pack.others) == 'table') and pack.others or {}
    local invBucket = (type(pack) == 'table' and tonumber(pack.invokerBucket or 0)) or 0
    if Logger and Logger.debug then
      local count = #others
      Logger.debug('assayer:client:awaitNearby:done', { requestId = requestId, count = count, invokerBucket = invBucket })
    end
    --//=-- Multi-request (radius): Always return primary wrapper to match others
    local invPid = PlayerId()
    local invSrc = GetPlayerServerId(invPid)
    local invName = GetPlayerName(invPid) or 'unknown'
    local primary = {
      id = invSrc,
      source = tostring(invSrc),
      name = invName,
      data = selfData,
      primary = true,
      bucket = invBucket,
    }
    return { primary, others }
  end

  --//=-- Initialize the dispatch table on first use to avoid early binding
  if _oreDispatch == nil then
    _oreDispatch = {
      name = { type = 'name', fn = Medal.GV.Ore.name },
      communityname = { type = 'communityName', fn = Medal.GV.Ore.communityName },
      heartbeat = { type = 'heartbeat', fn = Medal.GV.Ore.heartbeat },
      cfxid = { type = 'cfxId', fn = Medal.GV.Ore.cfxId },
      job = { type = 'job', fn = Medal.GV.Ore.job },
      entitymatrix = { type = 'entityMatrix', fn = Medal.GV.Ore.entityMatrix },
      cameramatrix = { type = 'cameraMatrix', fn = Medal.GV.Ore.cameraMatrix },
      vehicle = { type = 'vehicle', fn = Medal.GV.Ore.vehicle },
    }
  end

  --//=-- Case-insensitive lookup using lowercase key
  local key = (type(oreType) == 'string') and string.lower(oreType) or nil
  if key and _oreDispatch[key] then
    local entry = _oreDispatch[key]
    if type(entry.fn) == 'function' then
      return entry.fn()
    end
  end

  --//=-- Handle bundle requests, which assay multiple ore types at once
  if oreType == 'bundle' and type(req.types) == 'table' then
    local results = {}
    for _, subType in pairs(req.types) do
      local result = Medal.GV.Ore.assay(subType)
      if result ~= nil then
        results[subType] = result
      end
    end
    return results
  end

  --//=-- Unknown ore type
  return nil
end