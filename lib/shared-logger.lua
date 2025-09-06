--[[
  Medal.tv - FiveM Resource
  =========================
  File: lib/shared-logger.lua
  =====================
  Description:
    Shared logger module
  ---
  Exports:
    None
  ---
  Globals:
    - Logger: The Logger module table
]]

local levels = {
    error = 1,
    warning = 2,
    info = 3,
    debug = 4
}

local prefixes = {
    '^1[ERROR]',
    '^3[WARN]',
    '^7[INFO]',
    '^6[DEBUG]'
}

---@param level number
---@param ... any
local function log(level, ...)
    if level == levels.debug and Config and not Config.Debug then
        return
    end

    local args = { ... }

    local jsonException = function (reason, value)
        if type(value) == 'function' then
            return tostring(value)
        end

        return reason
    end

    for i = 1, #args do
        local arg = args[i]
        args[i] = type(arg) == 'table' and json.encode(arg, { indent = true, sort_keys = true, exception = jsonException }) or tostring(arg)
    end

    print(('^5[Medal] %s %s^7'):format(prefixes[level], table.concat(args, '\t')))
end

---#### Global Logger Module
---Provides logging functionality with different severity levels.
---All functions accept variable arguments and forward them to the underlying log function.
Logger = {
    ---#### Log an error message
    ---Logs messages at the ERROR level, typically used for serious issues
    ---that may cause resource failure or unexpected behavior.
    ---@param ... any
    error = function (...) log(levels.error, ...) end,

    ---#### Log a warning message
    ---Logs messages at the WARN level, used for potentially problematic
    ---situations that don't prevent normal operation but should be noted.
    ---@param ... any
    warning = function (...) log(levels.warning, ...) end,

    ---#### Log an informational message
    ---Logs messages at the INFO level, used for general information
    ---about resource flow and significant events.
    ---@param ... any
    info = function (...) log(levels.info, ...) end,

    ---#### Log a debug message
    ---Logs messages at the DEBUG level, typically used during development
    ---for detailed diagnostic information and troubleshooting.
    ---@param ... any
    debug = function (...) log(levels.debug, ...) end,
}
