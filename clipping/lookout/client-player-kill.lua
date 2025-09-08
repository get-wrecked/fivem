--[[
  Medal.tv - FiveM Resource
  =========================
  File: clipping/lookout/client-player-kill.lua
  =====================
  Description:
    Handles player kill events for auto clipping
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.AC.Lookout.handlePlayerKill : Handles player kill events for auto clipping
]]

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
