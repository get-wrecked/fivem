--[[
  Medal.tv - FiveM Resource
  =========================
  File: superSoaker/client-main.lua
  =====================
  Description:
    SuperSoaker client flow for requesting captures and routing NUI responses.
    Turns screenshots into "water" (screenshots). Filling the Soaker captures a frame;
    Shooting the Soaker uploads the screenshot to a URL.
  ---
  Exports:
    - fillSoaker - Fills the Soaker with a screenshot
    - shootWater - Shoots the Soaker to upload the screenshot to a URL
  ---
  Globals:
    None
]]

---@alias SoakerEncoding "jpg"|"png"|"webp"

---@class SoakerOptions
---@field encoding? SoakerEncoding
---@field quality? number # 0..1
---@field headers? table<string, string>

---@class SoakerInternalRequest: SoakerOptions
---@field correlation string
---@field resultURL? string
---@field targetURL? string
---@field targetField? string
---@field preferMedal? boolean

--//=-- SuperSoaker client: turns screenshots into "water" and NUI posts back to us.

---@class SoakerResultEntry
---@field cb fun(data:string)
---@type table<string, SoakerResultEntry>
local results = {}

---@type integer
local correlation = 0

---Generate a correlation id and store callback
---@param cb fun(data:string)
---@return string id
--//=-- Generate a correlation id and store callback
local function registerCorrelation(cb)
    local id = tostring(correlation)
    results[id] = { cb = cb }
    correlation = correlation + 1
    return id
end

Medal = Medal or {}
Medal.Shared = Medal.Shared or {}
Medal.Shared.Utils = Medal.Shared.Utils or {}

 ---NUI callback: water created (screenshot ready)
 ---@param body { id: string, data: string }
 ---@param cb fun(ok:boolean)
local function waterCreated(body, cb)
  cb(true)

  if body and body.id and results[body.id] then
      local entry = results[body.id]
      results[body.id] = nil
      Medal.Shared.Utils.logBase64Payload('[SuperSoaker.Client]', 'NUI -> client waterCreated', body.data)
      --//=-- deliver the water (data URL or response text)
      Medal.Shared.Utils.logBase64Payload('[SuperSoaker.Client]', 'Client -> callback waterCreated', body.data)
      entry.cb(body.data)
  end
end

RegisterNuiCallback('soaker_waterCreated', waterCreated)

---Send a capture request to the NUI capture runtime
---@param opts SoakerInternalRequest
--//=-- Send a capture request to NUI
local function sendRequest(opts)
    opts = opts or {}
    opts.preferMedal = Config.Screenshots.MedalPreferred

    SendNUIMessage({ request = opts})
end

---Fill the Soaker (capture locally and return data URI via callback)
---@param options SoakerOptions|fun(data:string)
---@param cb? fun(data:string)
local function fillSoaker(options, cb)
    local realCb ---@type fun(data:string)
    local opts    ---@type SoakerOptions
    if Medal.Shared.Utils.isValidCallback(cb) then
        realCb = cb --[[@as fun(result:string)]]
        ---@cast options SoakerOptions
        opts = options
    else
        ---@cast options fun(data:string)
        realCb = options
        opts = { encoding = 'jpg' }
    end

    local req ---@type SoakerInternalRequest
    req = {
        encoding = opts.encoding or 'jpg',
        quality = opts.quality,
        headers = opts.headers,
        correlation = registerCorrelation(realCb),
        resultURL = ('https://%s/soaker_waterCreated'):format(GetCurrentResourceName()),
        targetURL = nil,
        targetField = nil,
    }

    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        local quality = req.quality ~= nil and tostring(req.quality) or 'default'
        Logger.debug('[SuperSoaker.Client]', 'fillSoaker quality', quality)
    end

    sendRequest(req)
end

exports('fillSoaker', fillSoaker)

if Config.Screenshots.ScreenshotBasicOverride then
    AddEventHandler('__cfx_export_screenshot-basic_requestScreenshot', function (setCb)
       setCb(fillSoaker)
    end)
end

---Shoot the water (upload to URL). Field is the form field name.
---@param url string
---@param field string
---@param options SoakerOptions|fun(result:string)
---@param cb? fun(result:string)
local function shootWater(url, field, options, cb)
    local realCb ---@type fun(result:string)
    local opts    ---@type SoakerOptions
    if Medal.Shared.Utils.isValidCallback(cb) then
        realCb = cb --[[@as fun(result:string)]]
        ---@cast options SoakerOptions
        opts = options
    else
        ---@cast options fun(result:string)
        realCb = options
        opts = { headers = {}, encoding = 'jpg' }
    end

    local req ---@type SoakerInternalRequest
    req = {
        encoding = opts.encoding or 'jpg',
        quality = opts.quality,
        headers = opts.headers or {},
        correlation = registerCorrelation(realCb),
        resultURL = ('https://%s/soaker_waterCreated'):format(GetCurrentResourceName()),
        targetURL = url,
        targetField = field or 'file',
    }

    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        local quality = req.quality ~= nil and tostring(req.quality) or 'default'
        Logger.debug('[SuperSoaker.Client]', 'shootWater quality', quality)
    end

    sendRequest(req)
end

exports('shootWater', shootWater)

if Config.Screenshots.ScreenshotBasicOverride then
    AddEventHandler('__cfx_export_screenshot-basic_requestScreenshotUpload', function (setCb)
       setCb(shootWater)
    end)
end

---Server asks us to fill; we capture and shoot the data back to server
---@param options SoakerOptions
---@param id string
local function askFill(options, id)
  options = options or {}

  local req ---@type SoakerInternalRequest
  req = {
      encoding = options.encoding or 'jpg',
      quality  = options.quality,
      headers  = options.headers,
      resultURL = ('https://%s/soaker_waterCreated'):format(GetCurrentResourceName()),
      targetURL = nil,
      targetField = nil,
      correlation = registerCorrelation(function(data)
          Medal.Shared.Utils.logBase64Payload('[SuperSoaker.Client]', 'Client -> server waterReady', data)
          TriggerServerEvent('superSoaker:waterReady', id, data)
      end),
  }

  if type(Logger) == 'table' and type(Logger.debug) == 'function' then
      local quality = req.quality ~= nil and tostring(req.quality) or 'default'
      Logger.debug('[SuperSoaker.Client]', 'askFill quality', quality)
  end

  sendRequest(req)
end
RegisterNetEvent('superSoaker:askFill', askFill)