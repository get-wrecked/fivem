--//=-- GameVein Ore Assayer: Handling the data retrieval of various "ores" (chunks of game data) to pass off in "minecarts".
--//=-- -- Each different "ore" is a different source of data, and thus each "ore" is retrieved in a different way, by a different file.

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

--- Client-side Assayer API
---@class GameVeinAssayerClient
---@field getFrameworkKey fun(timeoutMs?: integer): FrameworkKey
---@type GameVeinAssayerClient
Medal.GV.Assayer = Medal.GV.Assayer or {}

--- Assay a requested ore, and return the relevant data
--- Accepted forms:
---  - string: Treated as the `type` (e.g., 'name')
---  - table: { type = 'name', ... }
--- @param req string|table
--- @return any result The data for the requested ore, or nil if unknown
function Medal.GV.Ore.assay(req)
    local oreType = nil

    if type(req) == 'string' then
        oreType = req
    elseif type(req) == 'table' and type(req.type) == 'string' then
        oreType = req.type
    end

    if oreType == 'name' then
        return Medal.GV.Ore.name()
    end

    if oreType == 'communityName' then
        return GameVein.Ore.communityName()
    end

    --//=-- Unknown ore type
    return nil
end

--//=-- In-flight results, keyed by request id
local pendingResults = {}

RegisterNetEvent('medal:gv:assayer:resFrameworkKey', function(reqId, key)
    pendingResults[reqId] = key
end)

--- Request the server framework key and wait for a response
--- @param timeoutMs? integer Optional timeout in milliseconds (default 5000)
--- @return FrameworkKey key The detected framework key, or 'unknown' on timeout
function Medal.GV.Assayer.getFrameworkKey(timeoutMs)
    --// TODO: Create a thread here ??? 
    local reqId = ('%d:%d'):format(Cache.player, GetGameTimer())
    --//=-- Send request to server
    TriggerServerEvent('medal:gv:assayer:reqFrameworkKey', reqId)

    --//=-- Await response with timeout
    local deadline = GetGameTimer() + (timeoutMs or 5000)
    while GetGameTimer() < deadline do
        local v = pendingResults[reqId]
        if v ~= nil then
            pendingResults[reqId] = nil
            return v
        end
        Wait(0)
    end

    --//=-- Timed out
    pendingResults[reqId] = nil
    return 'unknown'
end