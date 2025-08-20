RegisterNuiCallback('hide', function (_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
