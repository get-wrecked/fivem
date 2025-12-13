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
    Logger.debug('handleCustomEvent called', 'eventId=' .. tostring(eventId), 'toggle=' .. tostring(Settings.eventToggles[eventId]), 'clippingEnabled=' .. tostring(Settings.clippingEnabled))

    if Settings.eventToggles[eventId] then
        Logger.debug('handleCustomEvent -> vesselDepart', eventId)
        Medal.AC.vesselDepart({
            eventId = eventId,
            tags = tags
        })
    else
        Logger.debug('handleCustomEvent skipped (toggle off)', eventId)
    end
end
