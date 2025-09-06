--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/ore/client-vehicle.lua
  =====================
  Description:
    GameVein Ore: Vehicle (client)
    Provides the current (or last) player's vehicle identifier suitable for spawning,
    including the model hash and a human-readable name with class metadata.
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.GV.Ore.vehicle : Get the player's current (or last) vehicle information
]]

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

---@class VehicleInfo
---@field id string         #//=-- Spawn name that hashes to `hash` (best-effort; lowercase display key)
---@field name string       #//=-- Display or internal model name (localized when available)
---@field hash integer      #//=-- Model hash (use with CreateVehicle or similar)
---@field class integer     #//=-- GTA vehicle class id
---@field className string  #//=-- Human-readable vehicle class name

--- Build a default/unknown vehicle payload
---@return VehicleInfo
local function unknownVehicle()
  return { id = 'unknown', name = 'unknown', hash = 0, class = -1, className = 'unknown' }
end

--- Lookup table mapping GTA V vehicle class ids to names
---@type table<integer, string>
local VEHICLE_CLASS_NAMES = {
  [0] = 'Compacts',
  [1] = 'Sedans',
  [2] = 'SUVs',
  [3] = 'Coupes',
  [4] = 'Muscle',
  [5] = 'Sports Classics',
  [6] = 'Sports',
  [7] = 'Super',
  [8] = 'Motorcycles',
  [9] = 'Off-road',
  [10] = 'Industrial',
  [11] = 'Utility',
  [12] = 'Vans',
  [13] = 'Cycles',
  [14] = 'Boats',
  [15] = 'Helicopters',
  [16] = 'Planes',
  [17] = 'Service',
  [18] = 'Emergency',
  [19] = 'Military',
  [20] = 'Commercial',
  [21] = 'Trains',
}

--- Translate a class id to a friendly name
---@param classId integer
---@return string
local function getClassName(classId)
  return VEHICLE_CLASS_NAMES[classId] or 'unknown'
end

--- Resolve a best-effort display name for a model hash
---@param model integer
---@return string
local function resolveModelName(model)
  local key = GetDisplayNameFromVehicleModel(model)
  if type(key) == 'string' and #key > 0 then
    local label = GetLabelText(key)
    if type(label) == 'string' and label ~= 'NULL' and #label > 0 then
      return label
    end
    return key
  end
  return 'unknown'
end

--- Resolve a best-effort spawn name from the model hash.
--- Uses the display name key (usually the uppercase model code) lowercased.
--- Returns 'unknown' if not matching the current entity hash.
---@param model integer
---@return string
local function resolveSpawnName(model)
  local key = GetDisplayNameFromVehicleModel(model)
  if type(key) == 'string' and #key > 0 then
    local lower = string.lower(key)
    --//=-- Verify that hashing the candidate maps back to the same model hash
    local okLower = false
    local okUpper = false
    local hashLower = nil
    local hashUpper = nil
    pcall(function() hashLower = GetHashKey(lower) end)
    pcall(function() hashUpper = GetHashKey(key) end)
    okLower = (type(hashLower) == 'number' and hashLower == model)
    okUpper = (type(hashUpper) == 'number' and hashUpper == model)
    if okLower or okUpper then
      return lower --//=-- The returned hash is always lowercase, despite the test
    end
  end
  return 'unknown'
end

--- Get the player's current (or last) vehicle information
--- Returns a table with an `inVehicle` boolean, and a nested `vehicleInfo` payload.
---@return { inVehicle: boolean, vehicleInfo: VehicleInfo }
function Medal.GV.Ore.vehicle()
  --//=-- Use cached ped helper for consistency
  local ped = Cache:GetCachedPed()

  --//=-- Check current vehicle first
  local veh_current = GetVehiclePedIsIn(ped, false)
  local veh = veh_current
  local inVehicle = false

  if veh ~= 0 then
    inVehicle = true
  else
    --//=-- Fallback to last driven vehicle
    local veh_last = GetLastDrivenVehicle and GetLastDrivenVehicle() or 0
    if veh_last ~= 0 then
      veh = veh_last
      inVehicle = false --//=-- Not currently in the vehicle, but there was a last vehicle
    end
  end

  local vehicleInfo = veh ~= 0 and {
    id = resolveSpawnName(GetEntityModel(veh)),
    name = resolveModelName(GetEntityModel(veh)),
    hash = GetEntityModel(veh),
    class = GetVehicleClass(veh),
    className = getClassName(GetVehicleClass(veh))
  } or unknownVehicle()

  return { inVehicle = inVehicle, vehicleInfo = vehicleInfo }
end
