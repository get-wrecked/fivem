---@class Cache
---@field player number The local player index
---@field playerSrc number The player server id
---@field ped number The current player ped entity (changes when spawning/respawning)
local cache = {}

--- Cache update interval in milliseconds
local CACHE_UPDATE_INTERVAL = 100

---@protected
cache.__index = function (self, key)
    local value = rawget(self, key)

    if value ~= nil then
        return value
    end

    return rawget(cache, key)
end

---Create a new cache instance
---@protected
---@return table
function cache:new()
    local instance = setmetatable({}, self)

    return instance
end

---Set a cache value
---@param key string
---@param value any
function cache:set(key, value)
    rawset(self, key, value)
end

---Invalidate a specific cache entry
---@param key string
function cache:invalidate(key)
    rawset(self, key, nil)
end

---Check if a cache entry exists and is valid
---@param key string
---@return boolean
function cache:has(key)
    return rawget(self, key) ~= nil
end

---Initialize the cache instance and start background thread
---@protected
---@return table
function cache:initialize()
    self:set('player', PlayerId())
    self:set('playerSrc', GetPlayerServerId(PlayerId()))

    Citizen.CreateThread(function ()
        while true do
            Citizen.Wait(CACHE_UPDATE_INTERVAL)

            local ped = PlayerPedId()

            if ped ~= 0 and rawget(self, 'ped') ~= ped then
                rawset(self, 'ped', ped)
            end
        end
    end)

    return self
end

Cache = cache:new():initialize() --[[@as Cache]]
