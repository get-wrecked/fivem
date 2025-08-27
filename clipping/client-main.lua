Citizen.CreateThread(function ()
    Citizen.Wait(100)

    SendNUIMessage({
        action = 'clipping:details',
        payload = Medal.GV.Ore.assay('cfxId')
    })
end)
