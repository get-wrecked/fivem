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

--- Assay a requested ore, and return the relevant data
--- Accepted forms:
---  - string: Treated as the `type` (e.g., 'name')
---  - table: { type = 'name', ... }
--- @param req string|table
--- @return any result The data for the requested ore, or nil if unknown
function Medal.GV.Ore.assay(req)
  local oreType = nil

  if type(req) == 'string' then
    oreType = req
  elseif type(req) == 'table' and type(req.type) == 'string' then
    oreType = req.type
  end

  if oreType == 'name' then
    return Medal.GV.Ore.name()
  end

  if oreType == 'communityName' then
    return Medal.GV.Ore.communityName()
  end

  if oreType == 'heartbeat' then
    return Medal.GV.Ore.heartbeat()
  end

  if oreType == 'cfxId' then
    return Medal.GV.Ore.cfxId()
  end

  if oreType == 'job' then
    return Medal.GV.Ore.job()
  end

  if oreType == 'entityMatrix' then
    return Medal.GV.Ore.entityMatrix()
  end

  if oreType == 'cameraMatrix' then
    return Medal.GV.Ore.cameraMatrix()
  end

  if oreType == 'vehicle' then
    return Medal.GV.Ore.vehicle()
  end

  --//=-- Unknown ore type
  return nil
end