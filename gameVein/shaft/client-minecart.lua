--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/shaft/client-minecart.lua
  =====================
  Description:
    GameVein Minecart: sending JSON payloads via the NUI WebSocket client
  ---
  Exports:
    NUI Callbacks:
      - `ws:minecart`: Assays an ore and sends it in a minecart to NUI, via `ws:send`
  ---
  Globals:
    - Medal.GV.pushMinecart : Sends a payload over the NUI WebSocket client's connection
]]

Medal = Medal or {}
Medal.GV = Medal.GV or {} --//=-- Just in case

--- Push a minecart: Send a payload over the NUI WebSocket client's connection.
--- Overloads:
---  - pushMinecart(type: string, data?: any)
---  - pushMinecart(envelope: { type: string, data?: any })
---  - pushMinecart(any) -> wraps into { type = 'raw', data = value }
--- @param a string|table|any First argument: Either a string, an envelope table, or any value (for raw)
--- @param b string|table|any Optional second argument: Data when the first arg is a string
function Medal.GV.pushMinecart(a, b)
  local envelope

  if type(a) == 'string' then
    envelope = { type = a, data = b }
  elseif type(a) == 'table' and type(a.type) == 'string' then
    envelope = a
  else
    envelope = { type = 'raw', data = a }
  end

  SendNUIMessage({ action = 'ws:send', payload = envelope })
end

--//=-- NUI: Minecart ore endpoint (assay and push ore in a minecart to NUI, via ws:send)
RegisterNuiCallback('ws:minecart', function(req, cb)
  --//=-- Capture ore type for improved error logging when pcall fails
  local reqOreType = nil
  local ok, result = pcall(function()
    --//=-- Normalize incoming request from NUI
    local norm = req
    --//=-- Debug: log raw request
    if Logger and Logger.debug then
      Logger.debug('minecart:reqRaw', norm)
    end
    --//=-- Unwrap nested payload/data up to a few levels to be resilient to wrappers
    for _ = 1, 3 do
      if type(norm) == 'table' then
        if type(norm.payload) == 'table' then
          norm = norm.payload
        elseif type(norm.data) == 'table' then
          norm = norm.data
        else
          break
        end
      else
        break
      end
    end
    --//=-- If we received a bare array like { 'name', 'job' }, treat it as a bundle
    if type(norm) == 'table' and type(norm.type) ~= 'string' and norm[1] ~= nil then
      norm = { type = 'bundle', types = norm }
    end

    --//=-- Debug: log normalized request shape
    if Logger and Logger.debug then
      Logger.debug('minecart:reqNorm', norm)
    end

    local ore = Medal.GV.Ore.assay(norm)
    local oreType = nil
    if type(norm) == 'string' then
      oreType = norm
    elseif type(norm) == 'table' and type(norm.type) == 'string' then
      oreType = norm.type
    end
    --//=-- Stash for outer error logging scope
    reqOreType = oreType

    if oreType ~= nil and ore ~= nil then
      --//=-- Debug: log successful assay summary
      if Logger and Logger.debug then
        local summary = ore
        if type(ore) == 'table' then
          local keys = {}
          for k, _ in pairs(ore) do keys[#keys+1] = tostring(k) end
          summary = { keys = keys }
        end
        Logger.debug('minecart:assayed', { type = oreType, summary = summary })
      end
    Medal.GV.pushMinecart(oreType, ore)
      return true
    end

    return { error = 'ore-unavailable' }
  end)

  if not ok then
    --//=-- Include the ore type and error reason in logs to aid debugging
    Logger.error('minecart-assay-failed', { req = req, oreType = reqOreType, err = result })
    cb({ error = 'minecart-assay-failed' })
    return
  end

  cb(result)
end)
