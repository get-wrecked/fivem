---@class Settings
---@field clipLength number
---@field clippingEnabled boolean
---@field eventToggles table<string, boolean>
local settings = {}
settings.__index = settings

---Create a new settings instance
---@protected
---@return table
function settings:new()
    local instance = setmetatable({}, self)

    return instance
end

function settings:save()
    SetResourceKvpInt('medal:clip-length', self.clipLength)
    SetResourceKvpInt('medal:clip-enabled', self.clippingEnabled and 1 or 0)
end

---Initialize the settings instance and set settings values
---@protected
---@return table
function settings:initialize()
    self.clipLength = GetResourceKvpInt('medal:clip-length') == 0 and 30 or GetResourceKvpInt('medal:clip-length')
    self.clippingEnabled = GetResourceKvpInt('medal:clip-enabled') == 1

    return self
end

Settings = settings:new():initialize() --[[@as Settings]]
