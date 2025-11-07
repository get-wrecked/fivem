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

local pending = {}
local corr = 0

--//=-- Generate a simple correlation id
local function nextCorrelation()
    corr = corr + 1
    return tostring(corr)
end

 ---Event from client when water (image) is ready
 ---@param id string
 ---@param data string
 RegisterNetEvent('superSoaker:waterReady', function(id, data)
    local src = source
    local entry = pending[id]
    if entry ~= nil then
        pending[id] = nil
        --//=-- Return to the original callback
        Medal.Shared.Utils.logBase64Payload('[SuperSoaker.Server]', 'Client -> server waterReady', data)
        local ok, err = pcall(entry.cb, false, data, src)
        if not ok then
            print(('SuperSoaker callback error: %s'):format(err))
        end
    end
end)

--//=-- Export: request water from a given player; options mirrors screenshot-basic (encoding, quality, headers, etc.)
---@param playerSrc number
---@param options SoakerOptions
---@param cb SoakerServerCb
local function requestPlayerWater(playerSrc, options, cb)
    print('SuperSoaker Callback Type: ' .. json.encode(cb))
    
    if not Medal.Shared.Utils.isValidCallback(cb) then
        error('SuperSoaker: requestPlayerWater requires a callback (function or CFX function reference)')
    end

    local id = nextCorrelation()
    pending[id] = { cb = cb }

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

    --//=-- Ask the client to fill the soaker. Client will NUI-capture and reply via superSoaker:waterReady
    TriggerClientEvent('superSoaker:askFill', playerSrc, options or {}, id)
end

exports('requestPlayerWater', requestPlayerWater)

if Config.Screenshots.ScreenshotBasicOverride then
    AddEventHandler('__cfx_export_screenshot-basic_requestClientScreenshot', function (setCb)
        setCb(requestPlayerWater)
    end)
end
