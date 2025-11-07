--[[
  Medal.tv - FiveM Resource
  =========================
  File: superSoaker/server-main.lua
  =====================
  Description:
    Handles requesting water (screenshots) from clients and returning the data
    to supplied callbacks using simple correlation ids.
  ---
  Exports:
    - requestPlayerWater: Request water from a given player
  ---
  Globals:
    None
]]


---Callback invoked when a player's water is ready
---@alias SoakerServerCb fun(err:any, data:string, src:number)

Medal = Medal or {}
Medal.Shared = Medal.Shared or {}
Medal.Shared.Utils = Medal.Shared.Utils or {}

--//=-- Pending callbacks are now handled by the HTTP server with tokens

--//=-- Export: request water from a given player; options mirrors screenshot-basic (encoding, quality, headers, etc.)
---@param playerSrc number
---@param options SoakerOptions
---@param cb SoakerServerCb
local function requestPlayerWater(playerSrc, options, cb)
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        local serialized
        if type(json) == 'table' and type(json.encode) == 'function' then
            local ok, encoded = pcall(json.encode, cb)
            serialized = ok and encoded or '<json encode failed>'
        else
            serialized = '<json module unavailable>'
        end
        Logger.debug('[SuperSoaker.Server]', 'Callback Type', serialized)
    else
        print('SuperSoaker Callback Type: ' .. json.encode(cb))
    end
    
    if not Medal.Shared.Utils.isValidCallback(cb) then
        error('SuperSoaker: requestPlayerWater requires a callback (function or CFX function reference)')
    end

    --//=-- Generate unique token for this upload
    local token = exports['medal-fivem']:generateToken()
    
    --//=-- Register the token and callback with the HTTP server
    exports['medal-fivem']:registerUpload(token, playerSrc, cb)

    local optionsLog
    if type(options) == 'table' then
        optionsLog = {}
        for key, value in pairs(options) do
            if type(value) ~= 'function' then
                optionsLog[key] = value
            end
        end
    else
        optionsLog = options
    end
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        local serialized
        if type(optionsLog) == 'table' then
            if type(json) == 'table' and type(json.encode) == 'function' then
                local ok, encoded = pcall(json.encode, optionsLog)
                serialized = ok and encoded or '<json encode failed>'
            else
                serialized = '<options table>'
            end
        else
            serialized = tostring(optionsLog)
        end
        Logger.debug('[SuperSoaker.Server]', 'requestPlayerWater options', serialized)
    end

    --//=-- Build upload URL and send to client. Client will NUI-capture and upload via HTTP
    local uploadURL = ('http://%s/superSoaker/upload/%s'):format(GetCurrentResourceName(), token)
    TriggerClientEvent('superSoaker:askFillHTTP', playerSrc, options or {}, uploadURL)
end

exports('requestPlayerWater', requestPlayerWater)

if Config.Screenshots.ScreenshotBasicOverride then
    AddEventHandler('__cfx_export_screenshot-basic_requestClientScreenshot', function (setCb)
        setCb(requestPlayerWater)
    end)
end
