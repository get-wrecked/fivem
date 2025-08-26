---GameVein Ore: Community Name (server)
---Respond with the community project name or hostname to the requesting client.
---Uses the server convar: `sv_projectName` (preferred) and falls back to `sv_hostname`.
---@param requestId string
local function handleReqCommunityName(requestId)
  local playerSrc = source

  local projectName = GetConvar('sv_projectName', '')
  local hostName = GetConvar('sv_hostname', '')

  TriggerClientEvent('medal:gv:ore:resCommunityName', playerSrc, requestId, projectName ~= '' and projectName or hostName)
end


RegisterNetEvent('medal:gv:ore:reqCommunityName', handleReqCommunityName) --//=-- Register server event to service community name requests
