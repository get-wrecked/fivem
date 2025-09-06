--[[
  Medal.tv - FiveM Resource
  =========================
  File: lib/client-logger.lua
  =====================
  Description:
    Client Logger bridge: This is a NUI endpoint for UI to log via the shared Logger
    Handles  `https://${resource}/ws:log` to log via shared Logger
  ---
  Exports:
    NUI Callbacks: 
      - `ws:log`: Logs data to shared Logger
  ---
  Globals:
    None
]]

RegisterNUICallback('ws:log', function(data, cb)
  local level = (type(data) == 'table' and type(data.level) == 'string') and data.level or 'info'
  local args = (type(data) == 'table' and type(data.args) == 'table') and data.args or { data }

  --//=-- Resolve logger function; default to info
  local logFn = (Logger and Logger[level]) or (Logger and Logger.info)

  if type(logFn) == 'function' then
    --//=-- Spread args if available, else log a placeholder
    if type(args) == 'table' and next(args) ~= nil then
      logFn(table.unpack(args))
  else
      logFn('[NUI]', 'ws:log (no data)')
    end
  else
    print('[Medal] ws:log', level, json and json.encode(args) or tostring(args)) --//=-- Fallback print if Logger is unavailable for some reason
  end

  if cb then cb(true) end
end)
