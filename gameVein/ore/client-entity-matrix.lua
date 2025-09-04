--//=-- GameVein Ore: Entity Matrix (client)
--//=--   A helper function to retrieve an entity's world matrix vectors via 
--//=--   the `GET_ENTITY_MATRIX` native.

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

---@alias Entity number
---@class EntityMatrix
---@field right vector3
---@field forward vector3
---@field up vector3
---@field position vector3

--- Get an entity's world-space matrix: right, forward, up, and position vectors.
--- If no entity is provided, defaults to the player's ped (PlayerPedId()).
---@param entity Entity|nil
---@return EntityMatrix|nil
function Medal.GV.Ore.entityMatrix(entity)
  entity = entity or PlayerPedId()
  if not entity or entity == 0 then return nil end
  local right, forward, up, position = GetEntityMatrix(entity)
  return {
    right = right,
    forward = forward,
    up = up,
    position = position,
  }
end
