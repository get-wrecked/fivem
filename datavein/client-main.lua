---@class WsConfigLua
---@field host? string          # WebSocket host (default 127.0.0.1)
---@field port? integer         # WebSocket port (default 63325)
---@field protocol? 'ws'|'wss'  # WebSocket scheme (default 'ws')
---@field path? string          # Optional path, ex: `/socket`

--- Safely reads the WebSocket config from the shared `Config` table.
--- Accepts any of these, and the first present wins:
--- - `Config.DataVein.WebSocket`
--- - `Config.DataVein.WS`
--- - `Config.DataVein.Ws`
---@return WsConfigLua cfg
local function readWsConfig()
    --//=-- Start with empty, as the NUI side has defaults if fields are missing.
    local cfg = {}

    if type(Config) == 'table' then
        ---@type table|nil
        local ws = Config.DataVein.WebSocket or Config.DataVein.WS or Config.DataVein.Ws

        if type(ws) == 'table' then
            if type(ws.host) == 'string' then cfg.host = ws.host end
            if type(ws.port) == 'number' then cfg.port = ws.port end
            if type(ws.protocol) == 'string' then cfg.protocol = ws.protocol end
            if type(ws.path) == 'string' then cfg.path = ws.path end
        end
    end

    return cfg
end

--- Open (or request to open) the WebSocket, on the UI side, via NUI.
--- Sends `{ action = 'ws:connect', data = <cfg> }` to the UI.
local function openUiWebSocket()
    local cfg = readWsConfig()

    if Config and Config.Debug then
        --//=-- Basic debug printout (avoid JSON deps); include only present fields
        local parts = {}
        if cfg.host then parts[#parts+1] = ('host=%s'):format(cfg.host) end
        if cfg.port then parts[#parts+1] = ('port=%d'):format(cfg.port) end
        if cfg.protocol then parts[#parts+1] = ('protocol=%s'):format(cfg.protocol) end
        if cfg.path then parts[#parts+1] = ('path=%s'):format(cfg.path) end
        print(('[datavein] UI ws:connect ' .. table.concat(parts, ' ')))
    end

    SendNUIMessage({ action = 'ws:connect', data = cfg })
end

--//=-- Open the WebSocket connection, shortly after this resource starts
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(500)
        openUiWebSocket()
    end)
end)

--- Prospect the data vein: open or reopen the NUI WebSocket client's connection.
--- If `override` is provided, the configurations will be merged on top of values read from `Config`.
---@param override? WsConfigLua
local function prospectVein(override)
    --//=-- Merge override on top of config-derived values
    local base = readWsConfig()
    local cfg = base
    if type(override) == 'table' then
        cfg = {
            host = override.host or base.host,
            port = override.port or base.port,
            protocol = override.protocol or base.protocol,
            path = override.path or base.path,
        }
    end
    SendNUIMessage({ action = 'ws:connect', data = cfg })
end

--- Push a minecart: send a payload over the NUI WebSocket client's connection.
--- Non-string payloads will be stringified when needed.
---@param payload any
local function pushMinecart(payload)
    SendNUIMessage({ action = 'ws:send', data = payload })
end

