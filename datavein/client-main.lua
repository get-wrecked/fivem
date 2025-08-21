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

