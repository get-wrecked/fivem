RegisterNuiCallback('hide', function (_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterCommand(Config.Command, function ()
    Logger.debug('Opening Medal UI')

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'show',
        payload = false
    })
end, false)

if Config.Keybind and type(Config.Keybind) == 'string' then
    Logger.debug(('Registering Medal UI keymapping: %s'):format(Config.Keybind))
    RegisterKeyMapping(Config.Command, 'Open Medal Clipping UI', 'keyboard', Config.Keybind)
end
