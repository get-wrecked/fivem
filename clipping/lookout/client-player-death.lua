--//=-- Auto Clipping Lookout: Player Death
--//=-- Handles the Player Death Signal

Medal = Medal or {}
Medal.AC = Medal.AC or {}
Medal.AC.Lookout = Medal.AC.Lookout or {}

local eventId = 'player_death'

function Medal.AC.Lookout.handlePlayerDeath()
    local details = Medal.AC.readEventConfig(eventId)

    if details.enabled then
        Medal.AC.vesselDepart({
            eventId = eventId,
            eventName = details.title,
            tags = { 'Death' }
        })
    end
end
