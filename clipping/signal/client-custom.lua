--[[
  Medal.tv - FiveM Resource
  =========================
  File: clipping/signal/client-custom.lua
  =====================
  Description:
    Registers custom auto clipping event listeners and adds them to the UX
  ---
  Exports:
    None
  ---
  Globals:
    None
]]

Medal = Medal or {}
Medal.AC = Medal.AC or {}
Medal.AC.Lookout = Medal.AC.Lookout or {}

---@param event string
---@param options EventConfig
exports('registerSignal', function (event, options)
    if options.enabled then
        SendNUIMessage({
            action = 'ac:event:register',
            payload = options
        })

        RegisterNetEvent(event, function ()
            Medal.AC.Lookout.handleCustomEvent(options.id, options.tags or {})
        end)
    end
end)
