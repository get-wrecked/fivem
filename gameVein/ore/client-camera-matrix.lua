--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/ore/client-camera-matrix.lua
  =====================
  Description:
    GameVein Ore: Camera Matrix (client)
    A helper function to retrieve a camera's world matrix vectors via GET_CAM_MATRIX.
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.GV.Ore.cameraMatrix : Returns a camera's world-space matrix: right, forward, up, and position vectors
]]

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

---@alias Cam number
---@class CameraMatrix
---@field right vector3
---@field forward vector3
---@field up vector3
---@field position vector3

--- Normalize a vector to unit length.
--- Returns a zero vector when the input has zero magnitude.
---@param v vector3
---@return vector3
local function _normalize(v)
  local mag = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
  if mag == 0 then return vector3(0.0, 0.0, 0.0) end
  return vector3(v.x / mag, v.y / mag, v.z / mag)
end

--- Compute the cross product of vectors a × b.
---@param a vector3
---@param b vector3
---@return vector3
local function _cross(a, b)
  return vector3(
    a.y * b.z - a.z * b.y,
    a.z * b.x - a.x * b.z,
    a.x * b.y - a.y * b.x
  )
end

--- Convert degrees to radians.
---@param deg number
---@return number
local function _toRadians(deg)
  return deg * math.pi / 180.0
end

--- Convert a camera rotation (in degrees; pitch=`x`, roll=`y`, yaw=`z`) to a forward unit vector.
--- This uses yaw (`z`) and pitch (`x`); roll (`y`) is ignored for forward vector computation.
---@param rot vector3
---@return vector3
local function _rotationToForward(rot)
  --//=-- rot.x: pitch, rot.y: roll, rot.z: yaw (degrees)
  local z = _toRadians(rot.z)
  local x = _toRadians(rot.x)
  local cosX = math.cos(x)
  return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

--- Get a camera's world-space matrix: right, forward, up, and position vectors.
--- If no cam is provided, it uses the current rendering camera; otherwise, it falls back to gameplay
--- camera by approximating a matrix from `GetGameplayCamCoord/Rot` (ignores roll).
---@param cam Cam|nil
---@return CameraMatrix|nil
function Medal.GV.Ore.cameraMatrix(cam)
  cam = cam or GetRenderingCam()
  if cam and cam ~= 0 then
    local right, forward, up, position = GetCamMatrix(cam)
    return {
      right = right,
      forward = forward,
      up = up,
      position = position,
    }
  end

  --//=-- Fallback: build what I think is basically the matrix, from the gameplay camera (but, ignoring camera roll)
  local position = GetGameplayCamCoord()
  local rot = GetGameplayCamRot(2) --//=-- prefer ZYX order
  local forward = _normalize(_rotationToForward(rot))
  local worldUp = vector3(0.0, 0.0, 1.0)
  local right = _normalize(_cross(forward, worldUp))
  local up = _normalize(_cross(right, forward))
  return {
    right = right,
    forward = forward,
    up = up,
    position = position,
  }
end
