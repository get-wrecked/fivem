--//=-- Auto Clipping Lookout: Player Kill
--//=-- Handles the Player Kill Signal

Medal = Medal or {}
Medal.AC = Medal.AC or {}
Medal.AC.Lookout = Medal.AC.Lookout or {}

local eventId = 'player_kill'

function Medal.AC.Lookout.handlePlayerKill()
    local details = Medal.AC.readEventConfig(eventId)

    if details.enabled and Settings.eventToggles[eventId] then
        Medal.AC.vesselDepart({
            eventId = eventId,
            tags = { 'Kills' }
        })
    end
end
