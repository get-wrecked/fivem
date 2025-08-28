-- Auto Clipping client

Medal = Medal or {}
Medal.AC = Medal.AC or {} --//=-- The namespace for the client Auto Clipping functions

---Safely reads a specific event config from the shared `Config` table
---@param eventId string
---@return EventConfig
function Medal.AC.readEventConfig(eventId)
    local cfg = {}

    if type(Config) == 'table' then
        local events = Config.ClippingEvents

        if type(events) == 'table' then
            for _, event in ipairs(events) do
                if event.id == eventId then
                    cfg = event
                end
            end
        end
    end

    return cfg
end

---Register user-facing Medal UI command and keybinding
function Medal.AC.registerCommand()
    if type(Config.Command) ~= 'string' then
        Logger.error('Config.Command is set to a malformed string, cannot register Medal UI command')
        return
    end

    RegisterCommand(Config.Command, function ()
        Logger.debug('Opening Medal UI')

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'show',
            payload = true
        })
    end, false)

    if Config.Keybind and type(Config.Keybind) == 'string' then
        Logger.debug(('Registering Medal UI keymapping: %s'):format(Config.Keybind))
        RegisterKeyMapping(Config.Command, 'Open Medal Clipping UI', 'keyboard', Config.Keybind)
    end
end

--//=-- Send the server Cfx Id to client NUI to retrieve server details, shortly after this resource starts
AddEventHandler('onClientResourceStart', function (resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CreateThread(function ()
        Wait(100)

        Medal.AC.registerCommand()

        SendNUIMessage({
            action = 'ac:details',
            payload = Medal.GV.Ore.assay('cfxId')
        })
    end)
end)

RegisterNuiCallback('hide', function (_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
