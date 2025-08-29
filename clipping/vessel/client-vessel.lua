--//=-- Auto Clipping Vessel: Sends normalized JSON payloads to NUI recorder connection

Medal = Medal or {}
Medal.AC = Medal.AC or {}

---@param cargo VesselCargo
function Medal.AC.vesselDepart(cargo)
    SendNUIMessage({
        action = ('ac:clip:%s'):format(cargo.eventId),
        payload = {
            key = Config.MedalApiKey,
            tags = cargo.tags or {}
        }
    })
end

RegisterNuiCallback('ac:event:toggle', function (data, cb)
    Settings.eventToggles[data.id] = data.toggle
    Settings:save()

    cb(true)
end)

RegisterNuiCallback('ac:event:enable', function (eventId, cb)
    cb(Settings.eventToggles[eventId])
end)
