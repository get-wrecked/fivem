--//=-- Shared helpers for request/response patterns used by GameVein ores

Medal = Medal or {}
Medal.GV = Medal.GV or {}
Medal.GV.Request = Medal.GV.Request or {}

--- Build a unique (enough) request id for the local player
--- Format: "<playerId>:<gameTimer>"
--- @return string requestId
function Medal.GV.Request.buildId()
  local pid = (Cache and Cache.player) or PlayerId()
  return ('%d:%d'):format(pid, GetGameTimer())
end

--- Await a response placed into the provided pending table keyed by request id
--- Cleans up the pending entry on success or timeout
--- @param pending table   --//=-- Table of in-flight results, keyed by requestId
--- @param requestId string
--- @param timeoutMs? integer  --//=-- Defaults to 5000
--- @param defaultValue any    --//=-- Value to return on timeout
--- @return any result
function Medal.GV.Request.await(pending, requestId, timeoutMs, defaultValue)
  local deadline = GetGameTimer() + (timeoutMs or 5000)
  while GetGameTimer() < deadline do
    local v = pending[requestId]
    if v ~= nil then
      pending[requestId] = nil
      return v
    end
    Wait(0)
  end

  pending[requestId] = nil
  return defaultValue
end
