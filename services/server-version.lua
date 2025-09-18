--[[
  Medal.tv - FiveM Resource
  =========================
  File: services/server-version.lua
  =====================
  Description:
    GitHub version check (server)
    Code originally created by Linden <https://github.com/thelindat> licensed under LGPL-3.0 <https://www.gnu.org/licenses/lgpl-3.0.en.html>
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.Services.Version.current: Current resource version
    - Medal.Services.Version.checkForUpdates: Checks current resource version against latest GitHub release
]]

Medal = Medal or {}
Medal.Services = Medal.Services or {}

---@class VersionService
---@field current string
---@field checkForUpdates fun(cb?: fun(hasUpdate: boolean): any): any
Medal.Services.Version = Medal.Services.Version or {}

local function noop() end

function Medal.Services.Version.checkForUpdates(cb)
    cb = cb or noop
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)

    if currentVersion then
        currentVersion = currentVersion:match('%d+%.%d+%.%d+')
    end

    if not currentVersion then
        cb(false)

        return Logger.error('Unable to determine current Medal resource version!')
    end

    Medal.Services.Version.current = currentVersion

    Citizen.SetTimeout(1000, function ()
        PerformHttpRequest('https://api.github.com/repos/get-wrecked/fivem/releases/latest', function (status, body)
            if status ~= 200 then
                return cb(false)
            end

            body = json.decode(body)

            if body.prerelease then
                return cb(false)
            end

            local latestVersion = body.tag_name:match('%d+%.%d+%.%d+')

            if not latestVersion or latestVersion == currentVersion then
                return cb(false)
            end

            local cv = { string.strsplit('.', currentVersion) }
            local lv = { string.strsplit('.', latestVersion) }

            for i = 1, #cv do
                local current, minimum = tonumber(cv[i]), tonumber(lv[i])

                if current ~= minimum then
                    if current < minimum then
                        print(('^3An update is available for %s (current version: %s)\r\n%s^0'):format(GetCurrentResourceName(), currentVersion, body.html_url))

                        cb(true)
                    else
                        break
                    end
                end
            end

            cb(false)
        end, 'GET')
    end)
end

Medal.Services.Version.checkForUpdates()
