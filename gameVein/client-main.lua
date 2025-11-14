--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/client-main.lua
  =====================
  Description:
    Loads the WebSocket config from `Config` (`../config.lua`) and opens the NUI WebSocket client's connection.
    Uses an NUI message of `ws:connect`
  ---
  Exports:
    None
  ---
  Globals:
    None
]]

--- @class WsConfigLua
--- @field host? string          # WebSocket host (default 127.0.0.1)
--- @field port? integer         # WebSocket port (default 12556)
--- @field protocol? WsProtocol  # WebSocket scheme (default 'ws')
--- @field path? string          # Optional path, ex: `/socket`
--- @field reconnectShortMs? integer        # First background retry delay in ms (default 30000)
--- @field reconnectLongMs? integer         # Subsequent silent retry delay in ms (default 120000)
--- @field reconnectShortAttempts? integer  # Number of short-interval attempts before switching to long interval (default 5)

Medal = Medal or {}
Medal.GV = Medal.GV or {} --//=-- The namespace for the client GameVein functions
Config = Config or {}
Config.GameVein = Config.GameVein or {}
Config.GameVein.WebSocket = Config.GameVein.WebSocket or {}
Config.GameVein.WS = Config.GameVein.WS or {}
Config.GameVein.Ws = Config.GameVein.Ws or {}
Config.Medal = Config.Medal or {}

--//=-- Special key code mapping for FiveM to JavaScript key codes
local SpecialKeyCodes = {
    ['b_116'] = 'WheelMouseMove.Up',
    ['b_115'] = 'WheelMouseMove.Up',
    ['b_100'] = 'MouseClick.LeftClick',
    ['b_101'] = 'MouseClick.RightClick',
    ['b_102'] = 'MouseClick.MiddleClick',
    ['b_1015'] = 'AltLeft',
    ['b_1000'] = 'ShiftLeft',
    ['b_2000'] = 'Space',
    ['b_1013'] = 'ControlLeft',
    ['b_1002'] = 'Tab',
    ['b_1014'] = 'ControlRight',
    ['b_140'] = 'Numpad4',
    ['b_142'] = 'Numpad6',
    ['b_144'] = 'Numpad8',
    ['b_141'] = 'Numpad5',
    ['b_143'] = 'Numpad7',
    ['b_145'] = 'Numpad9',
    ['b_200'] = 'Insert',
    ['b_1012'] = 'CapsLock',
    ['b_170'] = 'F1',
    ['b_171'] = 'F2',
    ['b_172'] = 'F3',
    ['b_173'] = 'F4',
    ['b_174'] = 'F5',
    ['b_175'] = 'F6',
    ['b_176'] = 'F7',
    ['b_177'] = 'F8',
    ['b_178'] = 'F9',
    ['b_179'] = 'F10',
    ['b_180'] = 'F11',
    ['b_181'] = 'F12',
    ['b_194'] = 'ArrowUp',
    ['b_195'] = 'ArrowDown',
    ['b_196'] = 'ArrowLeft',
    ['b_197'] = 'ArrowRight',
    ['b_1003'] = 'Enter',
    ['b_1004'] = 'Backspace',
    ['b_198'] = 'Delete',
    ['b_199'] = 'Escape',
    ['b_1009'] = 'PageUp',
    ['b_1010'] = 'PageDown',
    ['b_1008'] = 'Home',
    ['b_131'] = 'NumpadAdd',
    ['b_130'] = 'NumpadSubtract',
    ['b_211'] = 'Insert',
    ['b_210'] = 'Delete',
    ['b_212'] = 'End',
    ['b_1055'] = 'Home',
    ['b_1056'] = 'PageUp',
}

--- Translate FiveM key code to JavaScript key code
---@param key string
---@return string|nil
local function translateKey(key)
    if string.find(key, "t_") then
        --//=-- Regular character key (capture only first return value from gsub)
        local translatedKey = string.gsub(key, "t_", "")
        return translatedKey
    elseif SpecialKeyCodes[key] then
        --//=-- Special key from mapping
        return "SpecialCharacter." .. SpecialKeyCodes[key]
    end
    return nil
end

--- Safely reads the WebSocket config from the shared `Config` table.
--- Accepts any of these, and the first present wins:
--- - `Config.GameVein.WebSocket`
--- - `Config.GameVein.WS`
--- - `Config.GameVein.Ws`
---@return WsConfigLua cfg
function Medal.GV.readWsConfig()
    --//=-- Start with empty, as the NUI side has defaults if fields are missing.
    local cfg = {}

    if type(Config) == 'table' then
        ---@type table|nil
        local ws = Config.GameVein.WebSocket or Config.GameVein.WS or Config.GameVein.Ws

        if type(ws) == 'table' then
            if type(ws.host) == 'string' then cfg.host = ws.host end
            if type(ws.port) == 'number' then cfg.port = ws.port end
            if type(ws.protocol) == 'string' then cfg.protocol = ws.protocol end
            if type(ws.path) == 'string' then cfg.path = ws.path end
            --//=-- Optional reconnect intervals (ms)
            if type(ws.reconnectShortMs) == 'number' then cfg.reconnectShortMs = ws.reconnectShortMs end
            if type(ws.reconnectLongMs) == 'number' then cfg.reconnectLongMs = ws.reconnectLongMs end
            if type(ws.reconnectShortAttempts) == 'number' then cfg.reconnectShortAttempts = ws.reconnectShortAttempts end
        end
    end

    return cfg
end

--- Open (or request to open) the WebSocket, on the UI side, via NUI.
--- Sends `{ action = 'ws:connect', payload = <cfg> }` to the UI.
function Medal.GV.openUiWebSocket()
    local cfg = Medal.GV.readWsConfig()

    if Config and Config.Debug then
        --//=-- Basic debug printout (avoid JSON deps); include only present fields
        local parts = {}
        if cfg.host then parts[#parts+1] = ('host=%s'):format(cfg.host) end
        if cfg.port then parts[#parts+1] = ('port=%d'):format(cfg.port) end
        if cfg.protocol then parts[#parts+1] = ('protocol=%s'):format(cfg.protocol) end
        if cfg.path then parts[#parts+1] = ('path=%s'):format(cfg.path) end
        if cfg.reconnectShortMs then parts[#parts+1] = ('shortMs=%d'):format(cfg.reconnectShortMs) end
        if cfg.reconnectLongMs then parts[#parts+1] = ('longMs=%d'):format(cfg.reconnectLongMs) end
        if cfg.reconnectShortAttempts then parts[#parts+1] = ('shortAttempts=%d'):format(cfg.reconnectShortAttempts) end
        print(('[gamevein] UI ws:connect ' .. table.concat(parts, ' ')))
    end

    SendNUIMessage({ action = 'ws:connect', payload = cfg })
end

--- Get the currently bound key for a command
---@param command string The command name
---@return string|nil The JavaScript-compatible key code, or nil if not found
function Medal.GV.getCurrentKeybind(command)
    Logger.debug('[Medal.GV] getCurrentKeybind called with command: ' .. tostring(command))
    
    --//=-- Use FiveM native hash function with bitwise OR, as per FiveM examples
    local hash = GetHashKey(command)
    local commandHash = hash | 0x80000000
    
    Logger.debug(('[Medal.GV] Hash for "+%s": %s (0x%X)'):format(command, hash, commandHash))
    
    --//=-- GetControlInstructionalButton returns format like "~INPUT_XXXXXXXX~" or "t_X" or "b_XXX"
    local key = GetControlInstructionalButton(2, commandHash, true)
    Logger.debug('[Medal.GV] GetControlInstructionalButton returned: "' .. tostring(key) .. '" (type: ' .. type(key) .. ')')
    
    if not key or key == '' or key == '~INPUT_0~' then
        Logger.debug('[Medal.GV] No valid key binding found')
        return nil
    end
    
    --//=-- Strip ~INPUT_XXXXXXXX~ format if present
    if string.find(key, "~INPUT_") then
        Logger.debug('[Medal.GV] Key is in ~INPUT_~ format, cannot translate to keyboard key')
        return nil
    end
    
    local translated = translateKey(key)
    Logger.debug('[Medal.GV] translateKey returned: ' .. tostring(translated))
    
    return translated
end

--- Safely reads the Medal client config from the shared `Config` table.
---@return table cfg
function Medal.GV.readMedalConfig()
    local cfg = {}
    
    if type(Config) == 'table' then
        if type(Config.Medal) == 'table' then
            local medal = Config.Medal
            if type(medal.CheckIntervalMs) == 'number' then
                cfg.checkIntervalMs = medal.CheckIntervalMs
            end
        end
    end
    
    return cfg
end

--- Send Medal client configuration to the UI.
--- Sends `{ action = 'medal:config', payload = <cfg> }` to the UI.
function Medal.GV.sendMedalConfig()
    local cfg = Medal.GV.readMedalConfig()
    
    if Config and Config.Debug then
        local parts = {}
        if cfg.checkIntervalMs then parts[#parts+1] = ('checkIntervalMs=%d'):format(cfg.checkIntervalMs) end
        if #parts > 0 then
            Logger.debug(('[medal] UI medal:config ' .. table.concat(parts, ' ')))
        end
    end
    
    SendNUIMessage({ action = 'medal:config', payload = cfg })
end

--//=-- Open the WebSocket connection and send Medal config, shortly after this resource starts
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(500)
        Medal.GV.openUiWebSocket()
        Medal.GV.sendMedalConfig()
    end)
end)

