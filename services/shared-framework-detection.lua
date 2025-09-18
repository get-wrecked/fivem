--[[
  Medal.tv - FiveM Resource
  =========================
  File: services/shared-framework-detection.lua
  =====================
  Description:
    Shared framework helpers (client + server)
    Exposes a safe export helper for calling framework exports safely in any runtime.
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.Services.Framework.safeExport : Safely calls an export if available (client+server)
]]


Medal = Medal or {}
Medal.Services = Medal.Services or {}
Medal.Services.Framework = Medal.Services.Framework or {}

--//=-- Internal: check resource state if available in this runtime
---@param resource string
---@return boolean
local function isResourceStarted(resource)
  --//=-- Server provides GetResourceState; clients typically do not
  local ok, state = pcall(function()
    if type(GetResourceState) == 'function' then
      return GetResourceState(resource)
    end
    return nil
  end)
  return ok and state == 'started'
end

--//=-- Client+Server safe export helper
--- Safely calls an export from a resource.
--- On server, it will only call if the resource is started. On client, it checks exports[resource].
---@param resource string
---@param method string|string[]
---@param ... any
---@return any|nil
function Medal.Services.Framework.safeExport(resource, method, ...)
  if not resource or not exports then return nil end
  --//=-- If GetResourceState is available (server), require started; otherwise continue (client)
  if type(GetResourceState) == 'function' and (not isResourceStarted(resource)) then return nil end

  local ex = exports[resource]
  if not ex then return nil end

  local methods = type(method) == 'table' and method or { method }
  local args = { ... }
  for _, name in ipairs(methods) do
    local ok, result = pcall(function()
      local fn = ex and ex[name]
      if type(fn) == 'function' then
        --//=-- Call with explicit self to support ':' style exports
        return fn(ex, table.unpack(args))
      end
      return nil
    end)
    if ok and result ~= nil then return result end
  end
  return nil
end
