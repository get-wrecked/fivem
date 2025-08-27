--//=-- GameVein Ore: Job (client)
--//=-- Retrieves the player's job details via a server-backed request/await pattern.

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

local pendingResults = {}

---@param requestId string
---@param data Job
RegisterNetEvent('medal:gv:ore:resJob', function(requestId, data)
  pendingResults[requestId] = data
end)

---Get the player's job information
---@return Job
function Medal.GV.Ore.job()
  local requestId = Medal.GV.Request.buildId()
  TriggerServerEvent('medal:gv:ore:reqJob', requestId)
  return Medal.GV.Request.await(pendingResults, requestId, 5000, {
    id = 'unknown',
    name = 'unknown',
    rank = -1,
    rankName = 'unknown',
  })
end
