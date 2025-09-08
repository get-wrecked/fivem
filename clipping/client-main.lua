--[[
  Medal.tv - FiveM Resource
  =========================
  File: clipping/client-main.lua
  =====================
  Description:
    Auto Clipping client entry point, registering the commands and keybinds for the Medal Auto Clipping UI
    as well as creating the UI and sending server details to it.
  ---
  Exports:
    NUI Callbacks:
      - ac:toggle : Toggles the Auto Clipping UI
      - ac:length : Sets the Auto Clipping length
      - hide : "Hides" the UI via removing focus and cursor control
  ---
  Globals:
    - Medal.AC.readEventConfig : Safely reads a specific event config from the shared `Config` table
    - Medal.AC.registerCommand : Register user-facing Medal UI command and keybinding
    - Medal.AC.buildClippingUi : Setup the Auto Clipping UI with server details and enabled events
]]

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

---Setup the Auto Clipping UI with server details and enabled events
function Medal.AC.buildClippingUi()
    SendNUIMessage({
        action = 'ac:details',
        payload = Medal.GV.Ore.assay('cfxId')
    })

    SendNUIMessage({
        action = 'ac:enable',
        payload = Settings.clippingEnabled
    })

    SendNUIMessage({
        action = 'ac:length',
        payload = Settings.clipLength
    })

    for _, event in ipairs(Config.ClippingEvents) do
        if event.enabled then
            SendNUIMessage({
                action = 'ac:event:register',
                payload = event
            })
        end
    end
end

--//=-- Send the server Cfx Id to client NUI to retrieve server details, shortly after this resource starts
AddEventHandler('onClientResourceStart', function (resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CreateThread(function ()
        Wait(100)

        Medal.AC.registerCommand()
        Medal.AC.buildClippingUi()
    end)
end)

RegisterNuiCallback('ac:toggle', function (toggle, cb)
    Settings.clippingEnabled = toggle
    Settings:save()

    cb(true)
end)

RegisterNuiCallback('ac:length', function (length, cb)
    Settings.clipLength = tonumber(length)
    Settings:save()

    cb(true)
end)

RegisterNuiCallback('hide', function (_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
