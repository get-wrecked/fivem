--//=-- Auto Clipping Vessel: Sends normalized JSON payloads to NUI recorder connection

Medal = Medal or {}
Medal.AC = Medal.AC or {}

---@param cargo VesselCargo
function Medal.AC.vesselDepart(cargo)
    -- TODO
end

RegisterNuiCallback('ac:event:toggle', function (data, cb)
    Settings.eventToggles[data.id] = data.toggle
    Settings:save()

    cb(true)
end)

RegisterNuiCallback('ac:event:enable', function (eventId, cb)
    cb(Settings.eventToggles[eventId])
end)
