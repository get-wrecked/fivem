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
Logger = Logger or {}

--//=-- Pending callbacks are now handled by the HTTP server with tokens

--//=-- Safely serialize values for logging
local function serializeForLog(value)
    if type(json) == 'table' and type(json.encode) == 'function' then
        local ok, encoded = pcall(json.encode, value)
        if ok then
            return encoded
        end
        return '<json encode failed>'
    end

    if type(value) == 'table' then
        return '<json module unavailable>'
    end

    return tostring(value)
end

--//=-- Emit debug logs using the shared Logger when available, fallback to print if requested
local function debugLogValue(label, value, fallbackPrefix)
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        Logger.debug('[SuperSoaker.Server]', label, serializeForLog(value))
    elseif fallbackPrefix ~= nil then
        print(('%s: %s'):format(fallbackPrefix, serializeForLog(value)))
    end
end

--//=-- Export: request water from a given player; options mirrors screenshot-basic (encoding, quality, headers, etc.)
---@param playerSrc number
---@param options SoakerOptions
---@param cb SoakerServerCb
local function requestPlayerWater(playerSrc, options, cb)
    debugLogValue('Callback Type', cb, 'SuperSoaker Callback Type')
    
    if not Medal.Shared.Utils.isValidCallback(cb) then
        error('SuperSoaker: requestPlayerWater requires a callback (function or CFX function reference)')
    end

    --//=-- Verify exports exist
    local resourceName = GetCurrentResourceName()
    local exportExists = pcall(function()
        return exports[resourceName].generateToken ~= nil
    end)
    
    if not exportExists then
        if type(Logger) == 'table' and type(Logger.error) == 'function' then
            Logger.error('[SuperSoaker.Server]', 'generateToken export not found in resource', resourceName)
        else
            print(('[SuperSoaker.Server] ERROR: generateToken export not found in resource %s'):format(resourceName))
        end
        error('SuperSoaker: generateToken export not available')
    end

    --//=-- Ensure playerSrc is a number (was generally passed as string from tested callers)
    local playerSrcNum = tonumber(playerSrc)
    if not playerSrcNum then
        error(('SuperSoaker: Invalid playerSrc - cannot convert to number: %s'):format(tostring(playerSrc)))
    end
    
    --//=-- Generate unique token for this upload
    local token = exports[resourceName]:generateToken()
    
    --//=-- Debug log playerSrc
    debugLogValue('playerSrc type', type(playerSrc))
    debugLogValue('playerSrc value', playerSrc)
    
    --//=-- Register the token and callback with the HTTP server
    exports[resourceName]:registerUpload(token, playerSrcNum, cb)

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
    debugLogValue('requestPlayerWater options', optionsLog)

    --//=-- Build upload path and send to client. Client will construct full URL with GetCurrentServerEndpoint()
    local uploadPath = ('/%s/superSoaker/upload/%s'):format(GetCurrentResourceName(), token)
    TriggerClientEvent('superSoaker:askFillHTTP', playerSrc, options or {}, uploadPath)
end

exports('requestPlayerWater', requestPlayerWater)

if Config.Screenshots.ScreenshotBasicOverride then
    AddEventHandler('__cfx_export_screenshot-basic_requestClientScreenshot', function (setCb)
        setCb(requestPlayerWater)
    end)
end
