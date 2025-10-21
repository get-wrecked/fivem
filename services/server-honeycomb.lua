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
---@field playerJoin fun()
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
