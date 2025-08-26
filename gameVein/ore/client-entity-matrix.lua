--//=-- GameVein Ore: Entity Matrix (client)
--//=--   A helper function to retrieve an entity's world matrix vectors via 
--//=--   the `GET_ENTITY_MATRIX` native.

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

--- Get an entity's matrix (vectors and position)
--- If no entity is provided, this defaults to the player's ped.
---@param entity number|nil
---@return table|nil matrix { right: vector3, forward: vector3, up: vector3, position: vector3 }
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
