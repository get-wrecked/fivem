--//=-- GameVein Minecart: sending JSON payloads via the NUI WebSocket client

GameVein = GameVein or {} --//=-- Just in case

--- Push a minecart: Send a payload over the NUI WebSocket client's connection.
--- Overloads:
---  - pushMinecart(type: string, data?: any)
---  - pushMinecart(envelope: { type: string, data?: any })
---  - pushMinecart(any) -> wraps into { type = 'raw', data = value }
--- @param a string|table|any First argument: Either a string, an envelope table, or any value (for raw)
--- @param b string|table|any Optional second argument: Data when the first arg is a string
function GameVein.pushMinecart(a, b)
    local envelope

    if type(a) == 'string' then
        envelope = { type = a, data = b }
    elseif type(a) == 'table' and type(a.type) == 'string' then
        envelope = a
    else
        envelope = { type = 'raw', data = a }
    end

    SendNUIMessage({ action = 'ws:send', payload = envelope })
end
