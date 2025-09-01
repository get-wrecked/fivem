# gameVein/shaft

Transport helpers that open/close the NUI/UI WebSocket, and send envelopes (push "minecarts").

## Files & APIs

- `client-overseer.lua`
  - `Medal.GV.prospectVein(override?: { host?, port?, protocol?, path? })`
    - Merge overrides with `Config.GameVein.*`, and ask NUI/UI to connect with `ws:connect`.
  - `Medal.GV.sealShaft(code?: number, reason?: string)`
    - Ask NUI/UI to close, using `ws:close`.
- `client-minecart.lua`
  - `Medal.GV.pushMinecart(type: string, data?: any)` or `pushMinecart(envelope)`
    - Sends `{ action = 'ws:send', payload = { type, data } }` to NUI/UI.
  - NUI callback `ws:minecart`
    - Assays the requested ore and — if available — pushes it to NUI/UI (via a minecart).

## Examples

```lua
--//=-- Open with override
Medal.GV.prospectVein({ host = '127.0.0.1', port = 12556 })

--//=-- Send a custom payload
Medal.GV.pushMinecart('hello', { msg = 'from lua' })

--//=-- Close the socket
Medal.GV.sealShaft(1000, 'done')
```
