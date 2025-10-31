-- Callback to handle the purchase
QBCore.Functions.CreateCallback('TrunkMonkeys:server:BuyMonkeys', function(source, cb)
    local player = QBCore.Functions.GetPlayer(source)

    if not player then
        cb(false)
        return
    end

    -- Try to remove the money (checks both cash and bank)
    if player.Functions.RemoveMoney('cash', Config.MonkeyPrice, "bought-attack-monkeys") then
        cb(true) -- Payment successful
    else
        cb(false) -- Not enough money
    end
end)

-- Event to set the vehicle state after successful purchase
RegisterNetEvent('TrunkMonkeys:server:StoreMonkeysInVehicle', function(vehicleNetId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        -- Set a persistent state on the vehicle
        Entity(vehicle).state:set("hasMonkeys", true, true)
        player.Functions.Notify("A new batch of monkeys has been loaded into your vehicle's trunk.", "success")
    end
end)

-- Event to clear the vehicle state after monkeys are released
RegisterNetEvent('TrunkMonkeys:server:RemoveMonkeysFromVehicle', function(vehicleNetId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        -- Clear the state
        Entity(vehicle).state:set("hasMonkeys", false, true)
        player.Functions.Notify("The monkeys are loose!", "warning")
    end
end)

QBCore.Functions.CreateCallback('TrunkMonkeys:server:GetPlayerJob', function(source, cb, targetId)
    local target = QBCore.Functions.GetPlayer(targetId)
    if target then
        cb(target.PlayerData.job.name)
    else
        cb(nil)
    end
end)
