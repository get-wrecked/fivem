--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/ore/server-cfx-id.lua
  =====================
  Description:
    GameVein Ore: Cfx Id (server)
    Retrieves the server's Cfx Id from the web_baseUrl convar
  ---
  Exports:
    None
  ---
  Globals:
    Medal.GV.Ore.cfxIdServer: Get the server's Cfx Id
]]

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

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

function Medal.GV.Ore.cfxIdServer()
    return serverId
end

RegisterNetEvent('medal:gv:ore:reqCfxId', handleReqServerId)
