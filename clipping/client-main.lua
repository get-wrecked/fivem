-- Auto Clipping client

Medal = Medal or {}
Medal.AC = Medal.AC or {} --//=-- The namespace for the client Auto Clipping functions

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

--//=-- Send the server Cfx Id to client NUI to retrieve server details, shortly after this resource starts
AddEventHandler('onClientResourceStart', function (resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CreateThread(function ()
        Wait(100)

        SendNUIMessage({
            action = 'ac:details',
            payload = Medal.GV.Ore.assay('cfxId')
        })
    end)
end)
