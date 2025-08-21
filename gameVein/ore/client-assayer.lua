--//=-- GameVein Ore Assayer: Handling the data retrieval of various "ores" (chunks of game data) to pass off in "minecarts".
--//=-- -- Each different "ore" is a different source of data, and thus each "ore" is retrieved in a different way, by a different file.

GameVein = GameVein or {}
GameVein.Ore = GameVein.Ore or {}

--- Assay a requested ore, and return the relevant data
--- Accepted forms:
---  - string: Treated as the `type` (e.g., 'name')
---  - table: { type = 'name', ... }
--- @param req string|table
--- @return any result The data for the requested ore, or nil if unknown
function GameVein.Ore.assay(req)
    local oreType = nil

    if type(req) == 'string' then
        oreType = req
    elseif type(req) == 'table' and type(req.type) == 'string' then
        oreType = req.type
    end

    if oreType == 'name' then
        return GameVein.Ore.name()
    end

    --//=-- Unknown ore type
    return nil
end