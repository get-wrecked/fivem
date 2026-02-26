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
local function validateOptions(event, options)
    -- Validate required fields
    if type(event) ~= 'string' or event == '' then
        Logger.error('registerSignal: event must be a non-empty string')
        return false
    end
    if type(options) ~= 'table' then
        Logger.error('registerSignal: options must be a table (EventConfig)')
        return false
    end
    if type(options.id) ~= 'string' or options.id == '' then
        Logger.error('registerSignal: options.id must be a non-empty string')
        return false
    end
    if type(options.title) ~= 'string' or options.title == '' then
        Logger.error('registerSignal: options.title must be a non-empty string')
        return false
    end

    -- Validate optional fields if present
    if options.desc ~= nil and type(options.desc) ~= 'string' then
        Logger.error('registerSignal: options.desc must be a string if provided')
        return false
    end
    if options.enabled ~= nil and type(options.enabled) ~= 'boolean' then
        Logger.error('registerSignal: options.enabled must be a boolean if provided')
        return false
    end
    if options.tags ~= nil and type(options.tags) ~= 'table' then
        Logger.error('registerSignal: options.tags must be a table (string[]) if provided')
        return false
    end

    return true
end

---@param event string
---@param options EventConfig
exports('registerSignal', function (event, options)
    Logger.debug('Registering custom signal:', event)

    --//=-- Validate options
    if not validateOptions(event, options) then
        return
    end

    options.enabled = options.enabled ~= false
    Config.ClippingEvents[#Config.ClippingEvents+1] = options

    SendNUIMessage({
        action = 'ac:event:register',
        payload = options
    })

    --//=-- Load toggle state from KVP for custom events (not loaded by Settings:initialize)
    if Settings and Settings.eventToggles and options and options.id then
        if Settings.eventToggles[options.id] == nil then
            local kvpKey = ('medal:event:%s'):format(options.id)
            local kvpHandle = StartFindKvp(kvpKey)
            local keyExists = FindKvp(kvpHandle) ~= nil
            EndFindKvp(kvpHandle)

            if keyExists then
                --//=-- KVP exists, load the saved value
                Settings.eventToggles[options.id] = GetResourceKvpInt(kvpKey) == 1
            else
                --//=-- KVP doesn't exist, default to enabled and save
                Settings.eventToggles[options.id] = options.enabled
                SetResourceKvpInt(kvpKey, Settings.eventToggles[options.id] and 1 or 0)
            end
        end
    end

    RegisterNetEvent(event, function ()
        local enabled = Settings and Settings.eventToggles and Settings.eventToggles[options.id]
        Logger.debug('Custom signal fired:', event, 'eventId=' .. tostring(options.id), 'enabled=' .. tostring(enabled))

        --//=-- Dump full Settings snapshot for debugging
        if Logger and Logger.isDebugEnabled and Logger.isDebugEnabled() then
            if Settings then
                if json and type(json.encode) == 'function' then
                    Logger.debug('Custom signal Settings dump:', json.encode(Settings))
                else
                    Logger.debug('Custom signal Settings dump (no json.encode available):', tostring(Settings))
                end
            else
                Logger.debug('Custom signal Settings dump: Settings is nil')
            end
        end

        Medal.AC.Lookout.handleCustomEvent(options.id, options.tags or {})
    end)
end)
