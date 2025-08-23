--//=-- GameVein Ore: Player Name
--//=-- Retrieves the player's name, differing depending on the server's framework

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

local framework = 'none'

--- Get the current client's player name
--- @return string name The player's name or "unknown"
local function getFivemName()
    local name = GetPlayerName(-1) --//=-- The current player's name
    if type(name) == 'string' and #name > 0 then
        return name
    else
        return 'unknown'
    end
end

--- Get the current client's player name
--- @return string name The player's name or "unknown"
function Medal.GV.Ore.name()
  local playerName = 'unknown'

  if not framework or framework == 'none' then
    playerName = getFivemName()
  end

  return playerName
end