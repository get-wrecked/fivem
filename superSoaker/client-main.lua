--- SuperSoaker Client
 --- Turns screenshots into "water" (screenshots). Filling the Soaker captures a frame;
 --- shooting the Soaker uploads it. NUI posts results back using a correlation id.
 ---
 --- This module mirrors the behavior of screenshot-basic with supersoaker-themed API.
 --- Types and functions are annotated for Lua Language Server.

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

 ---NUI callback: water created (screenshot ready)
 ---@param body { id: string, data: string }
 ---@param cb fun(ok:boolean)
local function waterCreated(body, cb)
  cb(true)

  if body and body.id and results[body.id] then
      local entry = results[body.id]
      results[body.id] = nil
      --//=-- deliver the water (data URL or response text)
      entry.cb(body.data)
  end
end

RegisterNuiCallback('soaker_waterCreated', waterCreated)


 ---Send a capture request to the NUI capture runtime
 ---@param opts SoakerInternalRequest
 --//=-- Send a capture request to NUI
 local function sendRequest(opts)
    SendNUIMessage({ request = opts })
end

 ---Fill the Soaker (capture locally and return data URI via callback)
 ---@param options SoakerOptions|fun(data:string)
 ---@param cb? fun(data:string)
local function fillSoaker(options, cb)
    local realCb ---@type fun(data:string)
    local opts    ---@type SoakerOptions
    if type(cb) == 'function' then
        realCb = cb
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

    sendRequest(req)
 end

 exports('fillSoaker', fillSoaker)

 AddEventHandler('__cfx_export_screenshot-basic_requestScreenshot', function (setCb)
    setCb(fillSoaker)
 end)

 ---Shoot the water (upload to URL). Field is the form field name.
 ---@param url string
 ---@param field string
 ---@param options SoakerOptions|fun(result:string)
 ---@param cb? fun(result:string)
local function shootWater(url, field, options, cb)
    local realCb ---@type fun(result:string)
    local opts    ---@type SoakerOptions
    if type(cb) == 'function' then
        realCb = cb
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

    sendRequest(req)
 end

 exports('shootWater', shootWater)

 AddEventHandler('__cfx_export_screenshot-basic_requestScreenshotUpload', function (setCb)
    setCb(shootWater)
 end)

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
          TriggerServerEvent('superSoaker:waterReady', id, data)
      end),
  }

  sendRequest(req)
end
RegisterNetEvent('superSoaker:askFill', askFill)