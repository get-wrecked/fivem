--[[
  Medal.tv - FiveM Resource
  =========================
  File: clipping/vessel/client-vessel.lua
  =====================
  Description:
    Sends normalized JSON payloads to NUI recorder connection
  ---
  Exports:
    NUI Callbacks:
      - ac:event:toggle : Toggles an event's clipping state
      - ac:event:enable : Checks if an event is enabled
  ---
  Globals:
    - Medal.AC.vesselDepart : Sends normalized JSON payloads to NUI Medal recorder connection
]]

Medal = Medal or {}
Medal.AC = Medal.AC or {}

---@param cargo VesselCargo
function Medal.AC.vesselDepart(cargo)
    local action = ('ac:clip:%s'):format(cargo.eventId)
    Logger.debug('vesselDepart sending NUI', 'action=' .. action, 'tags=' .. json.encode(cargo.tags or {}))

    SendNUIMessage({
        action = action,
        payload = cargo.tags or {}
    })
end

RegisterNuiCallback('ac:event:toggle', function (data, cb)
    Logger.debug('NUI ac:event:toggle', 'id=' .. tostring(data.id), 'toggle=' .. tostring(data.toggle))
    Settings.eventToggles[data.id] = data.toggle
    Settings:save()

    cb(true)
end)

RegisterNuiCallback('ac:event:enable', function (eventId, cb)
    Logger.debug('NUI ac:event:enable', 'eventId=' .. tostring(eventId), 'result=' .. tostring(Settings.eventToggles[eventId]))
    cb(Settings.eventToggles[eventId])
end)
