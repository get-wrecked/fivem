--//=-- DataVein Overseer: open/re-open and close the WebSocket connection via NUI

DataVein = DataVein or {} --//=-- Just in case

--//=-- Prospect the data vein: open or reopen the NUI WebSocket client's connection.
--//=-- If `override` is provided, the configurations will be merged on top of values read from `Config`.
---@param override? table
function DataVein.prospectVein(override)
    --//=-- Merge override on top of config-derived values
    local base = DataVein.readWsConfig()
    local cfg = base

    if type(override) == 'table' then
        cfg = {
            host = override.host or base.host,
            port = override.port or base.port,
            protocol = override.protocol or base.protocol,
            path = override.path or base.path,
        }
    end

    SendNUIMessage({ action = 'ws:connect', data = cfg })
end

--//=-- Seal the shaft: Close the NUI WebSocket client's connection — with an optional code and reason.
---@param code? integer
---@param reason? string
function DataVein.sealShaft(code, reason)
    SendNUIMessage({ action = 'ws:close', data = { code = code, reason = reason } })
end
