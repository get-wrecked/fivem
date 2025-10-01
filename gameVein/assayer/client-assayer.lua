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
--//=-- Lazy-initialized, lowercase-keyed dispatch for ore types
--//=-- Each value holds the canonical `type` casing and its function
local _oreDispatch = nil

--- Assay a requested ore, and return the relevant data
--- Accepted forms:
---  - string: Treated as the `type` (e.g., 'name')
---  - table: { type = 'name', ... }
---  - table: { type = 'bundle', types = { 'name', 'job' } }
--- @param req string|table
--- @return any|table|nil The data for the requested ore, a table of results for a bundle, or nil if unknown
function Medal.GV.Ore.assay(req)
  local oreType = nil

  if type(req) == 'string' then
    oreType = req
  elseif type(req) == 'table' and type(req.type) == 'string' then
    oreType = req.type
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