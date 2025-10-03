--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/assayer/server-assayer.lua
  =====================
  Description:
    Server coordinator for nearby ore requests. Aggregates data from nearby players (OneSync Infinity compatible).
  ---
  Exports:
    None
  ---
  Globals:
    None
]]

print('Medal [assayer] server loaded')

--//=-- Assayer defaults (override via Config.Assayer if present)
local ASSAYER_DEFAULT_RADIUS = (Config and Config.Assayer and tonumber(Config.Assayer.ProximityRadius)) or 60.0
local ASSAYER_DEFAULT_TIMEOUT_MS = (Config and Config.Assayer and tonumber(Config.Assayer.RequestTimeoutMs)) or 1500
local ASSAYER_BUCKET_MISMATCH_LOG_TOLERANCE = (Config and Config.Assayer and tonumber(Config.Assayer.BucketMismatchLogTolerance)) or 5.0

--//=-- Pending aggregation state keyed by requestId
local PendingNearby = {}

--//=-- Safe distance calculation between two coords
---@class vector3
---@class vector4
---@alias CoordLike vector3|vector4|{ x: number, y: number, z: number, w?: number }|number[]

--- Normalize a coord-like value into a vector3, or nil if invalid
--- @param c CoordLike
--- @return vector3|nil
local function normalizeCoord(c)
  if not c then return nil end
  local t = type(c)
  if t == 'vector3' then return c end
  if t == 'vector4' then return vector3(c.x, c.y, c.z) end
  if t == 'table' then
    local x = (c.x or c[1])
    local y = (c.y or c[2])
    local z = (c.z or c[3])
    if x ~= nil and y ~= nil and z ~= nil then
      return vector3(tonumber(x) or 0.0, tonumber(y) or 0.0, tonumber(z) or 0.0)
    end
  end
  return nil
end

--- Compute Euclidean distance using vector length (#(a-b)). Returns a large number when invalid.
--- Extra arguments are ignored (backward compatible with prior callers).
--- @param a CoordLike
--- @param b CoordLike
--- @return number
local function distance(a, b, _)
  local va = normalizeCoord(a)
  local vb = normalizeCoord(b)
  if not va or not vb then return 1e9 end
  return #(va - vb)
end

--//=-- Finalize and respond to invoker if not already sent
local function finalizeNearby(requestId)
  local st = PendingNearby[requestId]
  if not st or st.sent then return end
  st.sent = true
  --//=-- Send list of nearby players' data back to invoker
  if Logger and Logger.debug then
    Logger.debug('assayer:server:finalizeNearby', { invoker = st.invoker, requestId = requestId, total = #(st.results or {}) })
  end
  TriggerClientEvent('medal:gv:assayer:resNearby', st.invoker, requestId, st.results, st.invokerBucket or 0)
  PendingNearby[requestId] = nil
end

--//=-- Receive ore data from a client we queried
RegisterNetEvent('medal:gv:assayer:resFromClient', function(requestId, invokerId, data)
  local src = source
  local st = PendingNearby[requestId]
  if not st or st.invoker ~= invokerId or st.sent then return end

  if data ~= nil then
    local bucket = (GetPlayerRoutingBucket and GetPlayerRoutingBucket(tostring(src))) or 0
    table.insert(st.results, {
      id = src,
      source = tostring(src),
      name = GetPlayerName(src) or 'unknown',
      data = data,
      primary = false,
      bucket = bucket,
    })
  end
  if Logger and Logger.debug then
    Logger.debug('assayer:server:resFromClient', { requestId = requestId, from = src, hasData = data ~= nil, responded = (st.responded or 0) + 1, expected = st.expected })
  end
  st.responded = st.responded + 1
  if st.responded >= st.expected then
    finalizeNearby(requestId)
  end
end)

--//=-- Entry point: invoker requests ores from nearby players
RegisterNetEvent('medal:gv:assayer:reqNearby', function(requestId, payload)
  local src = source
  local radius = tonumber(payload and payload.radius or ASSAYER_DEFAULT_RADIUS) or ASSAYER_DEFAULT_RADIUS
  local timeoutMs = tonumber(payload and payload.timeoutMs or ASSAYER_DEFAULT_TIMEOUT_MS) or ASSAYER_DEFAULT_TIMEOUT_MS
  local maxCount = tonumber(payload and (payload.max or payload.maxPlayers or payload.count) or 0) or 0
  local isBundle = type(payload) == 'table' and type(payload.types) == 'table'
  local ore = (not isBundle) and (payload and payload.ore) or nil

  if Logger and Logger.debug then
    Logger.debug('assayer:server:reqNearby:entry', { invoker = src, requestId = requestId, payload = payload })
  end

  --//=-- Normalize payload we forward to other clients (strip 'nearby')
  local forwardPayload = isBundle and { types = payload.types } or (ore and { ore = ore } or nil)

  --//=-- Validate forward payload
  if not forwardPayload then
    TriggerClientEvent('medal:gv:assayer:resNearby', src, requestId, {}, 0)
    return
  end

  if Logger and Logger.debug then
    Logger.debug('assayer:server:reqNearby', { invoker = src, requestId = requestId, radius = radius, max = maxCount, isBundle = isBundle, ore = ore, forward = forwardPayload })
  end

  --//=-- Try to get invoker ped and coords (OneSync required)
  local invokerPed = GetPlayerPed(src)
  if not invokerPed or invokerPed <= 0 then
    TriggerClientEvent('medal:gv:assayer:resNearby', src, requestId, {})
    return
  end
  local invokerCoords = GetEntityCoords(invokerPed)
  local invokerBucket = (GetPlayerRoutingBucket and GetPlayerRoutingBucket(tostring(src))) or 0
  if Logger and Logger.debug then
    Logger.debug('assayer:server:invokerBucket', { invoker = src, bucket = invokerBucket })
  end

  --//=-- Build candidate list based on same routing bucket and within radius, with distances
  local candidates = {}
  local players = GetPlayers()
  for _, sid in ipairs(players) do
    local pid = tonumber(sid) or -1
    if pid ~= src then
      local bucket = (GetPlayerRoutingBucket and GetPlayerRoutingBucket(tostring(sid))) or 0
      if bucket == invokerBucket then
        local ped = GetPlayerPed(pid)
        if ped and ped > 0 then
          local coords = GetEntityCoords(ped)
          local dist = distance(invokerCoords, coords, false)
          if dist <= radius then
            candidates[#candidates+1] = { pid = pid, dist = dist }
          end
        end
      else
        if Logger and Logger.debug then
          local ped = GetPlayerPed(pid)
          if ped and ped > 0 then
            local coords = GetEntityCoords(ped)
            local dist = distance(invokerCoords, coords, false)
            if dist <= (radius + ASSAYER_BUCKET_MISMATCH_LOG_TOLERANCE) then
              Logger.debug('assayer:server:skipBucketMismatch', { pid = pid, pidBucket = bucket, invokerBucket = invokerBucket, dist = dist })
            end
          end
        end
      end
    end
  end

  --//=-- Fallback: if no candidates matched bucket, retry ignoring bucket filter
  if #candidates == 0 then
    if Logger and Logger.debug then
      Logger.debug('assayer:server:retryNoBucket', { invoker = src, invokerBucket = invokerBucket, radius = radius })
    end
    for _, sid in ipairs(players) do
      local pid = tonumber(sid) or -1
      if pid ~= src then
        local ped = GetPlayerPed(pid)
        if ped and ped > 0 then
          local coords = GetEntityCoords(ped)
          local dist = distance(invokerCoords, coords, false)
          if dist <= radius then
            candidates[#candidates+1] = { pid = pid, dist = dist }
          end
        end
      end
    end
  end

  if Logger and Logger.debug then
    Logger.debug('assayer:server:candidates', { invoker = src, count = #candidates })
  end

  --//=-- Sort by nearest first
  table.sort(candidates, function(a, b) return (a.dist or 1e9) < (b.dist or 1e9) end)

  --//=-- Apply max limit if provided
  local targets = {}
  local limit = (maxCount and maxCount > 0) and math.min(maxCount, #candidates) or #candidates
  for i = 1, limit do
    targets[#targets+1] = candidates[i].pid
  end

  if Logger and Logger.debug then
    Logger.debug('assayer:server:targets', { invoker = src, expected = #targets, targets = targets })
  end

  if #targets == 0 then
    TriggerClientEvent('medal:gv:assayer:resNearby', src, requestId, {}, invokerBucket or 0)
    return
  end

  --//=-- Initialize pending state
  PendingNearby[requestId] = {
    invoker = src,
    expected = #targets,
    responded = 0,
    results = {},
    sent = false,
    invokerBucket = invokerBucket,
  }

  --//=-- Ask each nearby client to assay and respond
  for _, pid in ipairs(targets) do
    TriggerClientEvent('medal:gv:assayer:reqFromServer', pid, src, requestId, forwardPayload)
  end

  --//=-- Timeout to finalize if not all responses
  SetTimeout(timeoutMs, function()
    finalizeNearby(requestId)
  end)
end)
