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
Logger = Logger or {}

--//=-- Internal logging helpers with fallback to print
local function clientDebug(label, detail)
    if type(Logger) == 'table' and type(Logger.debug) == 'function' then
        if detail ~= nil then
            Logger.debug('[SuperSoaker.Client]', label, detail)
        else
            Logger.debug('[SuperSoaker.Client]', label)
        end
    end
end

local function clientError(label, detail)
    if type(Logger) == 'table' and type(Logger.error) == 'function' then
        if detail ~= nil then
            Logger.error('[SuperSoaker.Client]', label, detail)
        else
            Logger.error('[SuperSoaker.Client]', label)
        end
    else
        local suffix = detail ~= nil and (' - ' .. tostring(detail)) or ''
        print(('SuperSoaker Client Error: %s%s'):format(label, suffix))
    end
end

--//=-- Known encodings supported by the NUI capture
local validEncodings = {
    jpg = true,
    png = true,
    webp = true,
}

--//=-- Sanitize and validate headers object
local function sanitizeHeaders(headers)
    if headers == nil then
        return nil
    end

    if type(headers) ~= 'table' then
        clientError('askFillHTTP invalid headers type', type(headers))
        return nil
    end

    local sanitized = {}
    for key, value in pairs(headers) do
        if type(key) == 'string' and type(value) == 'string' then
            sanitized[key] = value
        else
            clientError('askFillHTTP header entry ignored', ('%s=%s'):format(tostring(key), tostring(value)))
        end
    end

    if next(sanitized) == nil then
        return nil
    end

    return sanitized
end

--//=-- Parse upload response payload and emit logging
local function handleUploadResponse(data, uploadURL)
    if type(data) ~= 'string' or data == '' then
        clientError('askFillHTTP upload response invalid', type(data))
        return
    end

    local decoded ---@type table|nil
    if type(json) == 'table' and type(json.decode) == 'function' then
        local ok, parsed = pcall(json.decode, data)
        if ok and type(parsed) == 'table' then
            decoded = parsed
        end
    end

    if decoded ~= nil and decoded.success ~= nil then
        if decoded.success == true then
            clientDebug('askFillHTTP upload success', uploadURL)
        else
            clientError('askFillHTTP upload failed', tostring(decoded.error or 'unknown error'))
        end
        return
    end

    Medal.Shared.Utils.logBase64Payload('[SuperSoaker.Client]', 'askFillHTTP raw response', data)
    clientDebug('askFillHTTP upload response length', tostring(#data))
end

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

---Server asks us to fill and upload via HTTP; we capture and upload directly to the server's HTTP endpoint
---@param options SoakerOptions
---@param uploadURL string
local function askFillHTTP(options, uploadURL)
    if type(uploadURL) ~= 'string' or uploadURL == '' then
        clientError('askFillHTTP called with invalid uploadURL', uploadURL)
        return
    end

    if options ~= nil and type(options) ~= 'table' then
        clientError('askFillHTTP options must be a table', type(options))
        options = {}
    end
    options = options or {}

    local encoding = options.encoding
    if encoding ~= nil then
        if not validEncodings[encoding] then
            clientError('askFillHTTP invalid encoding', encoding)
            encoding = nil
        end
    end
    encoding = encoding or 'jpg'

    local quality = options.quality
    if quality ~= nil then
        if type(quality) ~= 'number' or quality < 0 or quality > 1 then
            clientError('askFillHTTP invalid quality', tostring(quality))
            quality = nil
        end
    end

    local headers = sanitizeHeaders(options.headers)

    local req ---@type SoakerInternalRequest
    req = {
        encoding = encoding,
        quality  = quality,
        headers  = headers,
        resultURL = nil, --//=-- No callback needed; upload result is handled by server
        targetURL = uploadURL,
        targetField = nil, --//=-- Server expects JSON body, not multipart form
        correlation = registerCorrelation(function(data)
            handleUploadResponse(data, uploadURL)
        end),
    }

    clientDebug('askFillHTTP quality', quality ~= nil and tostring(quality) or 'default')

    sendRequest(req)
end
RegisterNetEvent('superSoaker:askFillHTTP', askFillHTTP)