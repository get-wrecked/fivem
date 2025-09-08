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
RegisterNUICallback('ws:minecart', function(req, cb)
  local ok, result = pcall(function()
    local ore = Medal.GV.Ore.assay(req)
    local oreType = nil
    if type(req) == 'string' then
      oreType = req
    elseif type(req) == 'table' and type(req.type) == 'string' then
      oreType = req.type
    end

    if oreType ~= nil and ore ~= nil then
    Medal.GV.pushMinecart(oreType, ore)
      return true
    end

    return { error = 'ore-unavailable' }
  end)

  if not ok then
    Logger.error('minecart-assay-failed', req)
    cb({ error = 'minecart-assay-failed' })
    return
  end

  cb(result)
end)
