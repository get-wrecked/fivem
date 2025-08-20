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

Logger = {
    error = function (...) log(levels.error, ...) end,
    warning = function (...) log(levels.warning, ...) end,
    info = function (...) log(levels.info, ...) end,
    debug = function (...) log(levels.debug, ...) end,
}
