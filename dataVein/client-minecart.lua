--//=-- DataVein Minecart: sending payloads via the NUI WebSocket client

DataVein = DataVein or {} --//=-- Just in case

--- Push a minecart: send a payload over the NUI WebSocket client's connection.
--- Non-string payloads will be stringified by NUI, when needed.
---@param payload any
function DataVein.pushMinecart(payload)
    SendNUIMessage({ action = 'ws:send', data = payload })
end
