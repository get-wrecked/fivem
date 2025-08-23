--//=-- GameVein Ore: Community Name (client)

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

local pendingResults = {}

RegisterNetEvent('medal:gv:ore:resCommunityName', function (requestId, name)
    pendingResults[requestId] = name
end)

---Get the community project name
---@return string icon The community project name or hostname
function Medal.GV.Ore.communityName()
function GameVein.Ore.communityName()
    local requestId = ('%d:%d'):format(Cache.player, GetGameTimer())

    TriggerServerEvent('medal:gv:ore:reqCommunityName', requestId)

    local deadline = GetGameTimer() + 5000
    while GetGameTimer() < deadline do
        local v = pendingResults[requestId]
        if v ~= nil then
            pendingResults[requestId] = nil
            return v
        end
        Wait(0)
    end

    pendingResults[requestId] = nil

    return 'FXServer'
end
