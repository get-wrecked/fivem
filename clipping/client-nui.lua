RegisterNuiCallback('hide', function (_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterCommand(Config.Command, function ()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'show',
        payload = false
    })
end, false)

if Config.Keybind and type(Config.Keybind) == 'string' then
    RegisterKeyMapping(Config.Command, 'Open Medal Clipping UI', 'keyboard', Config.Keybind)
end
