-- Auto Clipping client

Medal = Medal or {}
Medal.AC = Medal.AC or {} --//=-- The namespace for the client Auto Clipping functions

--//=-- Send the server Cfx Id to client NUI to retrieve server details, shortly after this resource starts
AddEventHandler('onClientResourceStart', function (resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    CreateThread(function ()
        Wait(100)

        SendNUIMessage({
            action = 'wt:details',
            payload = Medal.GV.Ore.assay('cfxId')
        })
    end)
end)
