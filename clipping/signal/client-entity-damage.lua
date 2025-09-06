--//=-- Auto Clipping Signal: Network Entity Damage
--//=-- Listens for the `CEventNetworkEntityDamage` game event

Medal = Medal or {}
Medal.AC = Medal.AC or {}
Medal.AC.Lookout = Medal.AC.Lookout or {}

AddEventHandler('gameEventTriggered', function (event, data)
    if event == 'CEventNetworkEntityDamage' then
        local isFatal = data[6] == 1
        local victimSrc = GetEntityServerId(data[1])
        local attackerSrc = GetEntityServerId(data[2])

        if isFatal then
            if victimSrc == Cache.playerSrc and data[1] == Cache.ped then
                Medal.AC.Lookout.handlePlayerDeath()
            elseif attackerSrc == Cache.playerSrc and victimSrc ~= Cache.playerSrc and victimSrc ~= 0 then
                Medal.AC.Lookout.handlePlayerKill()
            end
        end
    end
end)
