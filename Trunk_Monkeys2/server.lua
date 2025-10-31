-- Player data table
local playerData = {}

-- A placeholder function to get a player's job.
-- Server owners should replace this with their actual job-checking function.
function GetPlayerJob(source)
    -- This is just an example. You should replace this with your own logic.
    -- For instance, if you are using ESX, you might do something like:
    -- local xPlayer = ESX.GetPlayerFromId(source)
    -- return xPlayer.job.name
    return 'unemployed'
end

-- Basic notification function
local function notify(source, message, type)
    TriggerClientEvent('chat:addMessage', source, {
        color = { 255, 0, 0 },
        multiline = true,
        args = { "[TrunkMonkeys]", message }
    })
end

-- A placeholder function to remove money from a player.
-- Server owners should replace this with their actual economy system.
function RemoveMoney(source, amount)
    -- This is just an example. You should replace this with your own logic.
    -- For instance, if you are using ESX, you might do something like:
    -- local xPlayer = ESX.GetPlayerFromId(source)
    -- if xPlayer.getMoney() >= amount then
    --     xPlayer.removeMoney(amount)
    --     return true
    -- else
    --     return false
    -- end
    return true
end

-- Event to handle monkey purchase
RegisterNetEvent('TrunkMonkeys:server:BuyMonkeys', function()
    local src = source

    if not playerData[src] then
        playerData[src] = { hasMonkeys = false }
    end

    -- Check if player already has monkeys
    if playerData[src] and playerData[src].hasMonkeys then
        notify(src, "You can only carry one batch of monkeys at a time.", "error")
        return
    end

    -- Charge the player
    if RemoveMoney(src, Config.MonkeyPrice) then
        playerData[src].hasMonkeys = true
        TriggerClientEvent('TrunkMonkeys:client:ReceiveMonkeys', src)
        notify(src, "You paid $" .. Config.MonkeyPrice .. " for a batch of angry monkeys.", "success")
    else
        notify(src, "You don't have enough cash.", "error")
    end
end)

-- Event to handle monkey release
RegisterNetEvent('TrunkMonkeys:server:ReleaseMonkeys', function(plate, vehicleNetId)
    local src = source
    playerData[src].hasMonkeys = false

    -- Get all players except the source player
    local players = GetPlayers()
    local otherPlayers = {}
    for _, player in ipairs(players) do
        if tonumber(player) ~= src then
            table.insert(otherPlayers, player)
        end
    end

    TriggerClientEvent('TrunkMonkeys:client:SpawnMonkeys', src, vehicleNetId, otherPlayers)
end)

-- Player disconnect handling
AddEventHandler('playerDropped', function()
    local src = source
    if playerData[src] then
        playerData[src] = nil
    end
end)
