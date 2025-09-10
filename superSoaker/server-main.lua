--- SuperSoaker Server
--- Handles requesting water (screenshots) from clients and returning the data
--- to supplied callbacks using simple correlation ids.

---Callback invoked when a player's water is ready
---@alias SoakerServerCb fun(err:any, data:string, src:number)

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
    if type(cb) ~= 'function' then
        error('SuperSoaker: requestPlayerWater requires a callback')
    end

    local id = nextCorrelation()
    pending[id] = { cb = cb }

    --//=-- Ask the client to fill the soaker. Client will NUI-capture and reply via superSoaker:waterReady
    TriggerClientEvent('superSoaker:askFill', playerSrc, options or {}, id)
end

exports('requestPlayerWater', requestPlayerWater)

if Config.Screenshots.ScreenshotBasicOverride then
    AddEventHandler('__cfx_export_screenshot-basic_requestClientScreenshot', function (setCb)
        setCb(requestPlayerWater)
    end)
end
