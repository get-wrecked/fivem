--[[
  Medal.tv - FiveM Resource
  =========================
  File: gameVein/ore/client-heartbeat.lua
  =====================
  Description:
    GameVein Ore: Heartbeat
    Provides data for round-trip diagnostics
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.GV.Ore.heartbeat : Returns a heartbeat payload
]]

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Ore = Medal.GV.Ore or {}

--- Return a simple heartbeat payload
--- @return table payload { ok: boolean, ts: integer, pid: integer }
function Medal.GV.Ore.heartbeat()
  --//=-- Prefer cached values when available, or fallback
  local playerId = (type(Cache) == 'table' and Cache.player) or PlayerId()

  return {
    ok = true,
    ts = GetGameTimer(),
    pid = playerId,
  }
end
