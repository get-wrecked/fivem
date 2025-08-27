---GameVein Ore: Cfx Id (server)

local serverId = nil

Citizen.CreateThread(function ()
    local webUrl = ''

    repeat
        Citizen.Wait(10)
        webUrl = GetConvar('web_baseUrl', '')
    until webUrl ~= ''

    serverId = webUrl:match('%-(%w+)%.users')
end)

---@param requestId string
local function handleReqServerId(requestId)
    local playerSrc = source
    TriggerClientEvent('medal:gv:ore:resCfxId', playerSrc, requestId, serverId)
end

RegisterNetEvent('medal:gv:ore:reqCfxId', handleReqServerId)
