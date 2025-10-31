local menuOpen = false

-- Basic notification function
local function notification(message, type)
    -- We are using a basic chat message for notifications.
    -- Server owners can replace this with their preferred notification system.
    TriggerEvent('chat:addMessage', {
        color = { 255, 0, 0 },
        multiline = true,
        args = { "[TrunkMonkeys]", message }
    })
end

-- Create the NPC vendor
local npc = nil
CreateThread(function()
    local hash = GetHashKey(Config.NPCModel)
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Wait(20)
    end

    local x, y, z = Config.NPCLocation.coords.x, Config.NPCLocation.coords.y, Config.NPCLocation.coords.z
    local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 50.0, false)

    if not foundGround then
        print("[TrunkMonkeys] Could not find ground for NPC, using configured Z-coordinate as fallback.")
        groundZ = z
    end

    print("[TrunkMonkeys] Spawning NPC at coordinates: " .. x .. ", " .. y .. ", " .. groundZ)

    npc = CreatePed(4, hash, x, y, groundZ, Config.NPCLocation.heading, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    -- If the NPC still doesn't spawn correctly, you can try commenting out the line below.
    PlaceObjectOnGroundProperly(npc)
end)

-- Main loop for player interaction
CreateThread(function()
    while true do
        Wait(500) -- Check twice a second, no need to run every frame

        if menuOpen then
            Wait(100) -- Don't check if the menu is already open
            goto continue
        end

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if #(playerCoords - Config.NPCLocation.coords) < 5.0 then -- Only do raycast when player is close
            local forwardVector = GetEntityForwardVector(playerPed)
            local rayStart = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.5)
            local rayEnd = rayStart + forwardVector * 2.0

            local _, _, _, _, entityHit = GetShapeTestResult(StartShapeTestRay(rayStart.x, rayStart.y, rayStart.z, rayEnd.x, rayEnd.y, rayEnd.z, 2, playerPed, 4))

            if entityHit == npc then
                if not menuOpen then
                    SendNUIMessage({ action = 'open' })
                    menuOpen = true
                    SetNuiFocus(true, true)
                end
            end
        end
        ::continue::
    end
end)

-- Event handler for when the player receives monkeys
RegisterNetEvent('TrunkMonkeys:client:ReceiveMonkeys', function()
    notification("You have purchased a batch of angry monkeys! They are waiting in your trunk.", "success")
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, Config.VehicleCheckRadius, 0, 70)
    if DoesEntityExist(vehicle) then
        SetVehicleTrunkOpen(vehicle, false)
        Wait(1000)
        SetVehicleTrunkOpen(vehicle, true)
    end
end)

-- Command to release the monkeys
RegisterCommand('releasemonkeys', function()
    TriggerEvent('TrunkMonkeys:client:ReleaseMonkeys')
end, false)

-- Event to trigger monkey release (for phone integration, etc.)
RegisterNetEvent('TrunkMonkeys:client:ReleaseMonkeys', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, Config.VehicleCheckRadius, 0, 70)

    if DoesEntityExist(vehicle) then
        notification("The monkeys are loose! Good luck.", "success")
        TriggerServerEvent('TrunkMonkeys:server:ReleaseMonkeys', GetVehicleNumberPlateText(vehicle), NetworkGetNetworkIdFromEntity(vehicle))
    else
        notification("You need to be near a vehicle to release the monkeys.", "error")
    end
end)

RegisterNetEvent('TrunkMonkeys:client:SpawnMonkeys', function(vehicleNetId, playerData)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then return end

    SetVehicleTrunkOpen(vehicle, false)
    Wait(1000)

    local trunkOffset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.5, 0.5) -- Position behind the trunk
    local spawnedMonkeys = {}

    -- Create the monkeys
    for i = 1, Config.MonkeyCount do
        CreateThread(function()
            local hash = GetHashKey(Config.MonkeyModel)
            RequestModel(hash)
            while not HasModelLoaded(hash) do
                Wait(100)
            end

            local monkey = CreatePed(4, hash, trunkOffset.x, trunkOffset.y, trunkOffset.z, GetEntityHeading(vehicle), true, true)
            SetEntityAsMissionEntity(monkey, true, true)
            SetPedCombatAttributes(monkey, 46, true) -- Make them aggressive
            SetPedFleeAttributes(monkey, 0, 0)
            SetPedRelationshipGroupHash(monkey, GetHashKey("player"))
            table.insert(spawnedMonkeys, monkey)

            -- Find a target
            local peds = GetGamePool('CPed')
            local closestHostile = nil
            local closestHostileDist = -1

            for _, ped in ipairs(peds) do
                if IsPedHostile(ped, PlayerPedId()) and not IsPedAPlayer(ped) then
                    local dist = #(GetEntityCoords(ped) - GetEntityCoords(monkey))
                    if closestHostileDist == -1 or dist < closestHostileDist then
                        closestHostileDist = dist
                        closestHostile = ped
                    end
                end
            end

            if closestHostile and closestHostileDist < Config.MonkeySearchRadius then
                -- Found a hostile (someone shooting at player)
                TaskCombatPed(monkey, closestHostile, 0, 16)
            else
                -- No immediate threat, find player's target
                local targeted, targetEntity = GetPlayerTargetEntity(PlayerId())
                if targeted and IsPed(targetEntity) then
                    local isPlayer, player = IsPedAPlayer(targetEntity)
                    if isPlayer and not Config.OnDutyJobs[playerData[tostring(player)]] then
                        TaskCombatPed(monkey, targetEntity, 0, 16)
                    else
                        TaskCombatPed(monkey, targetEntity, 0, 16)
                    end
                else
                    -- No target, find the nearest player
                    local closestPlayer = nil
                    local closestDistance = -1

                    for player, job in pairs(playerData) do
                        local targetPed = GetPlayerPed(tonumber(player))
                        if DoesEntityExist(targetPed) and not Config.OnDutyJobs[job] then
                            local distance = #(GetEntityCoords(targetPed) - GetEntityCoords(monkey))
                            if closestDistance == -1 or distance < closestDistance then
                                closestPlayer = targetPed
                                closestDistance = distance
                            end
                        end
                    end
                    if closestPlayer and closestDistance < Config.MonkeySearchRadius then
                        TaskCombatPed(monkey, closestPlayer, 0, 16)
                    else
                        -- If no player target, find a random ped
                        local closestPed = nil
                        local closestDist = -1

                        for _, ped in ipairs(peds) do
                            if ped ~= monkey and IsPedHuman(ped) and not IsPedAPlayer(ped) then
                                local dist = #(GetEntityCoords(ped) - GetEntityCoords(monkey))
                                if closestDist == -1 or dist < closestDist then
                                    closestDist = dist
                                    closestPed = ped
                                end
                            end
                        end

                        if closestPed then
                            TaskCombatPed(monkey, closestPed, 0, 16)
                        end
                    end
                end
            end
        end)
    end

    -- Monkey lifecycle
    CreateThread(function()
        local startTime = GetGameTimer()
        local monkeysAreActive = true
        while monkeysAreActive do
            Wait(5000)
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
            local elapsedTime = GetGameTimer() - startTime
            if #spawnedMonkeys == _ or (activeCombatants == 0 and elapsedTime > 10000) or elapsedTime > Config.MonkeyMaxLifespan then
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

RegisterNUICallback('purchase', function(data, cb)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, Config.VehicleCheckRadius, 0, 70)
    if DoesEntityExist(vehicle) then
        local vehicleClass = GetVehicleClass(vehicle)
        if not Config.DisallowedClasses[vehicleClass] then
            TriggerServerEvent('TrunkMonkeys:server:BuyMonkeys', NetworkGetNetworkIdFromEntity(vehicle))
        else
            notification("You cannot store monkeys in this vehicle.", "error")
        end
    else
        notification("You need to be near a vehicle to store the monkeys.", "error")
    end
    SendNUIMessage({ action = 'close' })
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    SendNUIMessage({ action = 'close' })
    menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)
