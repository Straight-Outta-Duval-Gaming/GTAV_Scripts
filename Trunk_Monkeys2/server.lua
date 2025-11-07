local vehicleData = {}

-- A placeholder function to remove money from a player.
-- !! IMPORTANT !! Server owners MUST replace this with their actual economy system.
-- For testing purposes, this is set to TRUE. In a live environment, this means monkeys are FREE.
function RemoveMoney(source, amount)
    -- This is just an example. You should replace this with your own logic.
    return true
end

RegisterNetEvent('TrunkMonkeys:server:BuyMonkeys', function(vehiclePlate)
    local src = source

    if vehicleData[vehiclePlate] and vehicleData[vehiclePlate].hasMonkeys then
        TriggerClientEvent('TrunkMonkeys:client:Notify', src, "This vehicle already has monkeys.", "error")
        return
    end

    -- Charge the player
    if RemoveMoney(src, Config.MonkeyPrice) then
        vehicleData[vehiclePlate] = { hasMonkeys = true }
        TriggerClientEvent('TrunkMonkeys:client:Notify', src, "You paid $" .. Config.MonkeyPrice .. " for a batch of angry monkeys.", "success")
    else
        TriggerClientEvent('TrunkMonkeys:client:Notify', src, "You don't have enough cash.", "error")
    end
end)

RegisterNetEvent('TrunkMonkeys:server:ReleaseMonkeys', function(vehicleNetId, vehiclePlate)
    local src = source
    if not vehicleData[vehiclePlate] or not vehicleData[vehiclePlate].hasMonkeys then
        TriggerClientEvent('TrunkMonkeys:client:Notify', src, "You don't have any monkeys to release.", "error")
        return
    end
    vehicleData[vehiclePlate] = { hasMonkeys = false }

    local players = GetPlayers()
    local playersData = {}
    -- A placeholder for getting player jobs. Server owners must replace this.
    for _, player in ipairs(players) do
        if tonumber(player) ~= src then
            -- In a real server, you would get the player's job here.
            -- For example, with ESX:
            -- local xPlayer = ESX.GetPlayerFromId(tonumber(player))
            -- playersData[player] = xPlayer.job.name
            playersData[player] = 'unemployed' -- Placeholder
        end
    end

    TriggerClientEvent('TrunkMonkeys:client:SpawnMonkeys', src, vehicleNetId, playersData)
end)
