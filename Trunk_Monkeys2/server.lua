-- Vehicle data table
-- Note: This table is not persistent. If the server restarts, all monkey data will be lost.
-- For persistence, integrate this with your server's database or storage solution.
local vehicleData = {}

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
-- !! IMPORTANT !! Server owners MUST replace this with their actual economy system.
-- For testing purposes, this is set to TRUE. In a live environment, this means monkeys are FREE.
function RemoveMoney(source, amount)
    -- EXAMPLE for ESX:
    -- local xPlayer = ESX.GetPlayerFromId(source)
    -- if xPlayer.getMoney() >= amount then
    --     xPlayer.removeMoney(amount)
    --     return true
    -- else
    --     return false
    -- end

    -- EXAMPLE for QBCore:
    -- local Player = QBCore.Functions.GetPlayer(source)
    -- if Player.Functions.RemoveMoney('cash', amount) then
    --     return true
    -- else
    --     return false
    -- end

    return false
end

-- Event to handle monkey purchase
RegisterNetEvent('TrunkMonkeys:server:BuyMonkeys', function(vehicleNetId)
    local src = source

    -- Check if vehicle already has monkeys
    if vehicleData[vehicleNetId] and vehicleData[vehicleNetId].hasMonkeys then
        notify(src, "This vehicle already has monkeys.", "error")
        return
    end

    -- Charge the player
    if RemoveMoney(src, Config.MonkeyPrice) then
        vehicleData[vehicleNetId] = { hasMonkeys = true }
        TriggerClientEvent('TrunkMonkeys:client:ReceiveMonkeys', src)
        notify(src, "You paid $" .. Config.MonkeyPrice .. " for a batch of angry monkeys.", "success")
    else
        notify(src, "You don't have enough cash.", "error")
    end
end)

-- Event to handle monkey release
RegisterNetEvent('TrunkMonkeys:server:ReleaseMonkeys', function(plate, vehicleNetId)
    local src = source
    if not vehicleData[vehicleNetId] or not vehicleData[vehicleNetId].hasMonkeys then
        notify(src, "You don't have any monkeys to release.", "error")
        return
    end
    vehicleData[vehicleNetId] = { hasMonkeys = false }

    -- Get all players and their jobs
    local players = GetPlayers()
    local playerData = {}
    for _, player in ipairs(players) do
        if tonumber(player) ~= src then
            playerData[player] = GetPlayerJob(tonumber(player))
        end
    end

    TriggerClientEvent('TrunkMonkeys:client:SpawnMonkeys', src, vehicleNetId, playerData)
end)

-- Player disconnect handling
AddEventHandler('playerDropped', function()
    local src = source
end)
