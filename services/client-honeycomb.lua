--[[
  Medal.tv - FiveM Resource
  =========================
  File: services/client-honeycomb.lua
  =====================
  Description:
    HoneyComb player Medal status retrieval
  ---
  Exports:
    None
  ---
  Globals:
    None
]]

RegisterNuiCallback('services:medal-status', function (hasMedal, cb)
    TriggerServerEvent('medal:services:medalState', hasMedal)
    cb(true)
end)
