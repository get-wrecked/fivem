--[[
  Medal.tv - FiveM Resource
  =========================
  File: services/server-honeycomb.lua
  =====================
  Description:
    HoneyComb API for Medal integration stat tracking
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.Services.HoneyComb.startup: Send Cfx server id to Medal stat tracking endpoint
    - Medal.Services.HoneyComb.playerJoin: Send player Medal status to Medal stat tracking endpoint
]]

Medal = Medal or {}
Medal.Services = Medal.Services or {}

---@class StatService
---@field startup fun()
---@field playerJoin fun(fivemId: number, hasMedal: boolean)
Medal.Services.HoneyComb = Medal.Services.HoneyComb or {}

local function noop() end

function Medal.Services.HoneyComb.startup()
    PerformHttpRequest('https://medal.tv/fivem-server-plugin/events/startup', noop, 'POST', json.encode({
        server = Medal.GV.Ore.cfxIdServer(),
        version = Medal.Services.Version.current
    }), {
        ['Content-Type'] = 'application/json'
    })
end

function Medal.Services.HoneyComb.playerJoin(fivemId, hasMedal)
    PerformHttpRequest('https://medal.tv/fivem-server-plugin/events/player-join', noop, 'POST', json.encode({
        server = Medal.GV.Ore.cfxIdServer(),
        version = Medal.Services.Version.current,
        player = {
            id = fivemId,
            has_medal = hasMedal
        }
    }), {
        ['Content-Type'] = 'application/json'
    })
end

Citizen.CreateThread(function ()
    repeat
        Citizen.Wait(100)
    until Medal.GV.Ore.cfxIdServer() ~= nil and Medal.Services.Version.current ~= nil

    Medal.Services.HoneyComb.startup()
end)

RegisterNetEvent('medal:services:medalState', function (hasMedal)
    local fivemId = GetPlayerIdentifierByType(source, 'fivem')
    local _, id = string.strsplit(':', fivemId, 2)

    Medal.Services.HoneyComb.playerJoin(tonumber(id) --[[@as number]], hasMedal)
end)
