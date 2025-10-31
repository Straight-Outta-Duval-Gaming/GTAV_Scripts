local isSpawningMonkeys = false -- Debounce to prevent spam

-- Function to check if the vehicle is a valid type
local function IsVehicleValid(vehicle)
    if not DoesEntityExist(vehicle) then return false end

    local class = GetVehicleClass(vehicle)
    if Config.DisallowedClasses[class] then
        return false -- It's a bike, boat, heli, etc.
    end

    return true -- It's a valid car/truck/van
end

-- Function to get the player's vehicle if it's nearby and valid
local function GetNearbyValidVehicle()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Get the closest vehicle the player owns or has keys for
    local vehicle = QBCore.Functions.GetClosestVehicle(coords)
    if not vehicle or vehicle == 0 then
        return nil
    end

    -- Check distance
    local vehCoords = GetEntityCoords(vehicle)
    if #(coords - vehCoords) > Config.VehicleCheckRadius then
        return nil -- Too far away
    end

    -- Check if it's a valid type (not a bike/heli)
    if not IsVehicleValid(vehicle) then
        QBCore.Functions.Notify("Monkeys can't be stored in this type of vehicle.", "error")
        return nil
    end

    return vehicle
end

-- [[ NPC and Target Setup ]]
CreateThread(function()
    -- Request the NPC model
    RequestModel(Config.NPCModel)
    while not HasModelLoaded(Config.NPCModel) do
        Wait(100)
    end

    -- Spawn the NPC
    local npc = CreatePed(4, Config.NPCModel, Config.NPCLocation.coords.x, Config.NPCLocation.coords.y, Config.NPCLocation.coords.z + 50.0, Config.NPCLocation.heading, true, true)
    Wait(500) -- Wait for the entity to register
    PlaceObjectOnGroundProperly(npc)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    TaskStandStill(npc, -1) -- Tell the AI to not move

    -- Add a target option to the NPC
    exports['qb-target']:AddTargetEntity(npc, {
        options = {
            {
                type = "client",
                event = "TrunkMonkeys:client:AttemptPurchase",
                icon = "fas fa-monkey",
                label = "Buy Attack Monkeys ($" .. Config.MonkeyPrice .. ")",
            }
        },
        distance = 2.5
    })
end)

-- [[ Purchase Logic ]]
RegisterNetEvent('TrunkMonkeys:client:AttemptPurchase', function()
    local vehicle = GetNearbyValidVehicle()

    -- 1. Check if a valid vehicle is nearby
    if not vehicle then
        QBCore.Functions.Notify("You must be near one of your vehicles (car, truck, or van) to buy monkeys.", "error")
        return
    end

    -- 2. Check if the vehicle already has monkeys
    if Entity(vehicle).state.hasMonkeys then
        QBCore.Functions.Notify("Your vehicle is already full of monkeys!", "warning")
        return
    end

    -- 3. Attempt to pay
    QBCore.Functions.TriggerCallback('TrunkMonkeys:server:BuyMonkeys', function(success)
        if success then
            -- 4. Payment was good, store monkeys in the vehicle
            QBCore.Functions.Notify("Payment successful. Loading monkeys...", "success")
            local vehicleNetId = VehToNet(vehicle)
            TriggerServerEvent('TrunkMonkeys:server:StoreMonkeysInVehicle', vehicleNetId)
            SetVehicleTrunkOpen(vehicle, false)
            Wait(1000)
            SetVehicleTrunkOpen(vehicle, true)
        else
            -- 4. Payment failed
            QBCore.Functions.Notify("You don't have enough money.", "error")
        end
    end)
end)

-- [[ Release Logic ]]
-- This is the event your phone app needs to trigger.
RegisterNetEvent('TrunkMonkeys:client:ReleaseMonkeys', function()
    if isSpawningMonkeys then return end -- Stop spam

    local vehicle = GetNearbyValidVehicle()

    -- 1. Check if a valid vehicle is nearby
    if not vehicle then
        QBCore.Functions.Notify("You are not near a valid vehicle.", "error")
        return
    end

    -- 2. Check if the vehicle actually has monkeys
    if not Entity(vehicle).state.hasMonkeys then
        QBCore.Functions.Notify("You don't have any monkeys stored in this vehicle.", "error")
        return
    end

    -- 3. Set debounce and clear state
    isSpawningMonkeys = true
    local vehicleNetId = VehToNet(vehicle)
    TriggerServerEvent('TrunkMonkeys:server:RemoveMonkeysFromVehicle', vehicleNetId)

    -- 4. Open trunk and spawn monkeys
    SetVehicleTrunkOpen(vehicle, false) -- 'false' forces it open, 'true' forces it closed.

    CreateThread(function()
        -- Request monkey model
        RequestModel(Config.MonkeyModel)
        while not HasModelLoaded(Config.MonkeyModel) do
            Wait(100)
        end

        local playerPed = PlayerPedId()
        local trunkBone = GetEntityBoneIndexByName(vehicle, 'trunk')
        local spawnCoords = GetWorldPositionOfEntityBone(vehicle, trunkBone)
        local spawnedMonkeys = {}

        -- Create the relationship group
        local relGroup = GetHashKey("ATTACK_MONKEYS")
        SetRelationshipBetweenGroups(5, relGroup, GetPedRelationshipGroupHash(playerPed)) -- 5 = Companion
        SetRelationshipBetweenGroups(5, GetPedRelationshipGroupHash(playerPed), relGroup)

        for i = 1, Config.MonkeyCount do
            local monkey = CreatePed(4, Config.MonkeyModel, spawnCoords, GetEntityHeading(playerPed), true, true)
            SetPedRelationshipGroupHash(monkey, relGroup)
            SetPedCombatAttributes(monkey, 46, true) -- Can fight
            SetPedFleeAttributes(monkey, 0, false)   -- Won't flee
            SetEntityAsNoLongerNeeded(monkey)
            table.insert(spawnedMonkeys, monkey)
        end

        SetModelAsNoLongerNeeded(Config.MonkeyModel)

        -- 5. Task them to attack
        for _, monkey in pairs(spawnedMonkeys) do
            -- Find the closest *hostile* ped
            local closestEnemy, _ = QBCore.Functions.GetClosestPed(GetEntityCoords(monkey), {
                ignore = { playerPed },
                hostile = true
            }, Config.MonkeySearchRadius)

            if closestEnemy and closestEnemy ~= 0 then
                -- Found a hostile (someone shooting at player)
                TaskCombatPed(monkey, closestEnemy, 0, 16)
            else
                -- No immediate threat, find player's target
                local targeted, targetEntity = GetPlayerTargetEntity(PlayerId())
                if targeted and IsPed(targetEntity) then
                    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetEntity))
                    QBCore.Functions.TriggerCallback('TrunkMonkeys:server:GetPlayerJob', function(job)
                        if not Config.OnDutyJobs[job] then
                            TaskCombatPed(monkey, targetEntity, 0, 16)
                        end
                    end, targetServerId)
                else
                    -- No target, just wander
                    TaskWanderStandard(monkey, 10.0, 10)
                end
            end
        end

        isSpawningMonkeys = false -- Reset debounce, allowing new spawns if needed

        -- 6. Start a new thread to manage the monkeys' lifecycle
        CreateThread(function()
            local startTime = GetGameTimer()
            local lastCombatTime = GetGameTimer()
            local monkeysAreActive = true
            while monkeysAreActive do
                Wait(1000) -- Check every second
                local activeCombatants = 0
                local existingMonkeys = {}
                for _, monkey in pairs(spawnedMonkeys) do
                    if DoesEntityExist(monkey) then
                        table.insert(existingMonkeys, monkey)
                        if IsPedInCombat(monkey) then
                            activeCombatants = activeCombatants + 1
                        end
                    end
                end
                spawnedMonkeys = existingMonkeys

                if activeCombatants > 0 then
                    lastCombatTime = GetGameTimer()
                end

                local timeSinceLastCombat = GetGameTimer() - lastCombatTime
                local elapsedTime = GetGameTimer() - startTime

                if #spawnedMonkeys == 0 or timeSinceLastCombat > 10000 or elapsedTime > Config.MonkeyMaxLifespan then
                    monkeysAreActive = false
                end
            end
            for _, monkey in pairs(spawnedMonkeys) do
                if DoesEntityExist(monkey) then
                    ClearPedTasksImmediately(monkey)
                    TaskFleePed(monkey, PlayerPedId(), false, false, 15000, 0)
                end
            end
            Wait(15000)
            for _, monkey in pairs(spawnedMonkeys) do
                if DoesEntityExist(monkey) then
                    DeleteEntity(monkey)
                end
            end
        end)
    end)
end)

-- [[ Test Command / Phone Integration ]]
RegisterCommand('releasemonkeys', function()
    TriggerEvent('TrunkMonkeys:client:ReleaseMonkeys')
end, false)
