--//=-- GameVein Ore: Community Name (client)

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

local pendingResults = {}

RegisterNetEvent('medal:gv:ore:resCommunityName', function (requestId, name)
    pendingResults[requestId] = name
end)

---Get the community project name
---@return string name The community project name or hostname
function Medal.GV.Ore.communityName()
    local requestId = Medal.GV.Request.buildId()

    TriggerServerEvent('medal:gv:ore:reqCommunityName', requestId)

    return Medal.GV.Request.await(pendingResults, requestId, 5000, 'FXServer')
end
