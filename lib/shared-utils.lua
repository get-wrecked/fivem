--[[
  Medal.tv - FiveM Resource
  =========================
  File: lib/shared-utils.lua
  =====================
  Description:
    Shared utility helpers
  ---
  Exports:
    None
  ---
  Globals:
    - Medal.Shared.Utils : Shared utility helper functions
    - Medal.Shared.Utils.isValidCallback : Validates callback references, to make sure they are functions or function reference
    - Medal.Shared.Utils.logBase64Payload : Logs Base64 payload lengths when Logger.debug is available
]]


Medal = Medal or {}
Medal.Shared = Medal.Shared or {}
Medal.Shared.Utils = Medal.Shared.Utils or {}

--- Validate callback reference
--- Ensures the provided value is either a Lua function or a CFX function reference.
---@param cb? function | table Value to validate as a callback
---@return boolean isValid True when the callback is acceptable
function Medal.Shared.Utils.isValidCallback(cb)
  local cbType = type(cb)
  if cbType == "function" then
    return true
  end
  if cbType == "table" and cb.__cfx_functionReference then
    return true
  end
  return false
end

--- Log Base64 (data URI) payload length via Logger.debug when available
---@param tag string
---@param direction string
---@param payload any
function Medal.Shared.Utils.logBase64Payload(tag, direction, payload)
  if type(payload) ~= 'string' then return end
  if payload:sub(1, 5) ~= 'data:' then return end
  if type(Logger) ~= 'table' or type(Logger.debug) ~= 'function' then return end
  Logger.debug(tag, direction, 'Base64 Length:', #payload)
end
