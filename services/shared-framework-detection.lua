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

local LOG_TAG = '[Services.Framework.Shared]' --//=-- Log tag

--- Safe debug logger; prefers Logger.debug then Logger.info
--- @param ... any
local function sfLogDebug(...)
  local fn = nil
  if type(Logger) == 'table' then
    if type(Logger.debug) == 'function' then fn = Logger.debug
    elseif type(Logger.info) == 'function' then fn = Logger.info end
  end
  if fn then
    pcall(fn, LOG_TAG, ...)
  else
    print('[Medal]', LOG_TAG, ...)
  end
end

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
    local fn = ex and ex[name]
    if type(fn) == 'function' then
      --//=-- Most Cfx exports are plain functions: try without self first
      local ok1, res1 = pcall(fn, table.unpack(args))
      if ok1 and res1 ~= nil then return res1 end
      --//=-- Fallback: some frameworks expose colon-like exports; pass table as self
      local ok2, res2 = pcall(fn, ex, table.unpack(args))
      if ok2 and res2 ~= nil then return res2 end
    end
  end
  return nil
end
