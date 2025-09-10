--[[
  Medal.tv - FiveM Resource
  =========================
  File: clipping/lookout/client-custom-event.lua
  =====================
  Description:
    Handles custom export registered auto clipping events
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.AC.Lookout.handleCustomEvent : Handles custom events for auto clipping
]]

Medal = Medal or {}
Medal.AC = Medal.AC or {}
Medal.AC.Lookout = Medal.AC.Lookout or {}

---@param eventId string
---@param tags string[]
function Medal.AC.Lookout.handleCustomEvent(eventId, tags)
    if Settings.eventToggles[eventId] then
        Medal.AC.vesselDepart({
            eventId = eventId,
            tags = tags
        })
    end
end
