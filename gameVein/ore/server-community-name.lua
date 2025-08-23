RegisterNetEvent('medal:gameVein:ore:requestCommunityName', function (requestId)
    local playerSrc = source
    local projectName = GetConvar('sv_projectName', '')
    local hostName = GetConvar('sv_hostname', '')

    TriggerClientEvent('medal:gameVein:ore:receiveCommunityName', playerSrc, requestId, projectName ~= '' and projectName or hostName)
end)
