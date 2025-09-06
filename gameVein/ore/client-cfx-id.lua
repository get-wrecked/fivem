--//=-- GameVein Ore: Cfx Id (client)

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

local pendingResults = {}

RegisterNetEvent('medal:gv:ore:resCfxId', function (requestId, id)
    pendingResults[requestId] = id
end)

---Get the community Cfx Id
---@return string cfxId The global Cfx Id for the server license key
function Medal.GV.Ore.cfxId()
    local requestId = Medal.GV.Request.buildId()

    TriggerServerEvent('medal:gv:ore:reqCfxId', requestId)

    return Medal.GV.Request.await(pendingResults, requestId, 5000, nil)
end
