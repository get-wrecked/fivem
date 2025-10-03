--[[
  Medal.tv - FiveM Resource
  =========================
  File: services/client-version.lua
  =====================
  Description:
    GitHub version check client version accessor
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.Services.Version.current: Current resource version
]]

Medal = Medal or {}
Medal.Services = Medal.Services or {}

---@class VersionServiceClient
---@field current string
Medal.Services.Version = Medal.Services.Version or {}

RegisterNetEvent('medal:services:resVersion', function (version)
    Medal.Services.Version.current = version
end)

AddEventHandler('onClientResourceStart', function (resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CreateThread(function ()
        Wait(10)

        TriggerServerEvent('medal:services:reqVersion')
    end)
end)
