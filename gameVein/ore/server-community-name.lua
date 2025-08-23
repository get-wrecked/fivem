RegisterNetEvent('medal:gv:ore:reqCommunityName', function (requestId)
    local playerSrc = source
    local projectName = GetConvar('sv_projectName', '')
    local hostName = GetConvar('sv_hostname', '')

    TriggerClientEvent('medal:gv:ore:resCommunityName', playerSrc, requestId, projectName ~= '' and projectName or hostName)
end)
