--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/shaft/client-overseer.lua
  =====================
  Description:
    GameVein Overseer: open/re-open and close the WebSocket connection via NUI
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.GV.prospectVein : Open or reopen the WebSocket connection via NUI
    - Medal.GV.sealShaft : Close the WebSocket connection via NUI
]]

Medal = Medal or {}
Medal.GV = Medal.GV or {} --//=-- Just in case

--//=-- Prospect the game vein: open or reopen the NUI WebSocket client's connection.
--//=-- If `override` is provided, the configurations will be merged on top of values read from `Config`.
---@param override? table
function Medal.GV.prospectVein(override)
  --//=-- Merge override on top of config-derived values
  local base = Medal.GV.readWsConfig()
  local cfg = base

  if type(override) == 'table' then
    cfg = {
      host = override.host or base.host,
      port = override.port or base.port,
      protocol = override.protocol or base.protocol,
      path = override.path or base.path,
    }
  end

  SendNUIMessage({ action = 'ws:connect', payload = cfg })
end

--//=-- Seal the shaft: Close the NUI WebSocket client's connection — with an optional code and reason.
---@param code? integer
---@param reason? string
function Medal.GV.sealShaft(code, reason)
  local data = { code = code, reason = reason }
  SendNUIMessage({ action = 'ws:close', payload = data })
end

