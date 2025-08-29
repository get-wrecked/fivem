--//=-- The client-sided `Lib` entrypoint

---Get the supplied entity player server id if entity is a player
---@param entity number A client entity id
---@return number playerSrc Player server id or `0` if not found
function GetEntityServerId(entity)
    local owner = NetworkGetEntityOwner(entity)

    if owner and IsEntityAPed(entity) then
        return GetPlayerServerId(owner)
    end

    return 0
end
