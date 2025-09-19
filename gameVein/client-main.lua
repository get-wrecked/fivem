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

--//=-- Open the WebSocket connection, shortly after this resource starts
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(500)
        Medal.GV.openUiWebSocket()
    end)
end)

