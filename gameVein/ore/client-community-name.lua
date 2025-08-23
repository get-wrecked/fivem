GameVein = GameVein or {}
GameVein.Ore = GameVein.Ore or {}

local pendingResults = {}

RegisterNetEvent('medal:gameVein:ore:receiveCommunityName', function (requestId, name)
    pendingResults[requestId] = name
end)

---Get the community project name
---@return string icon The community project name or hostname
function GameVein.Ore.communityName()
    local requestId = ('%d:%d'):format(Cache.player, GetGameTimer())

    TriggerServerEvent('medal:gameVein:ore:requestCommunityName', requestId)

    local deadline = GetGameTimer() + 5000
    while GetGameTimer() < deadline do
        local v = pendingResults[requestId]
        if v ~= nil then
            pendingResults[requestId] = nil
            return v
        end
        Citizen.Wait(0)
    end

    pendingResults[requestId] = nil

    return 'FXServer'
end
