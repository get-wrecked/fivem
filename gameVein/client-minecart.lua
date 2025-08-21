--//=-- GameVein Minecart: sending payloads via the NUI WebSocket client

GameVein = GameVein or {} --//=-- Just in case

--- Push a minecart: send a payload over the NUI WebSocket client's connection.
--- Non-string payloads will be stringified by NUI, when needed.
---@param payload any
function GameVein.pushMinecart(payload)
    SendNUIMessage({ action = 'ws:send', data = payload })
end
