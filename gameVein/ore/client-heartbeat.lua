--//=-- GameVein Ore: Heartbeat
--//=-- Data for round-trip diagnostics

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
