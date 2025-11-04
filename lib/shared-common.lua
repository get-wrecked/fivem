--//=-- Check if value is a valid callback (function or CFX function reference)
local function isValidCallback(cb)
    local cbType = type(cb)
    if cbType == "function" then
        return true
    end
    if cbType == "table" and cb.__cfx_functionReference then
        return true
    end
    return false
end

Common = {
    isValidCallback = isValidCallback,
}
