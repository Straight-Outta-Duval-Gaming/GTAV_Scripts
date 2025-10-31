local playerJob = 'unemployed'
local hasMonkeys = false

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

-- Function to draw 3D text
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Create the NPC vendor
local npc = nil
CreateThread(function()
    local hash = GetHashKey(Config.NPCModel)
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Wait(20)
    end
    npc = CreatePed(4, hash, Config.NPCLocation.coords.x, Config.NPCLocation.coords.y, Config.NPCLocation.coords.z, Config.NPCLocation.heading, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    PlaceObjectOnGroundProperly(npc)
end)

-- Main loop for player interaction
CreateThread(function()
    while true do
        Wait(5)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())

        if npc and entity == npc and #(playerCoords - Config.NPCLocation.coords) < 3.0 then
            DrawText3D(Config.NPCLocation.coords.x, Config.NPCLocation.coords.y, Config.NPCLocation.coords.z + 1.0, '[E] - Buy Monkeys ($'..Config.MonkeyPrice..')')
            if IsControlJustReleased(0, 38) then
                -- Check for nearby vehicle before attempting to purchase
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
            end
        end
    end
end)

-- Event handler for when the player receives monkeys
RegisterNetEvent('TrunkMonkeys:client:ReceiveMonkeys', function()
    notification("You have purchased a batch of angry monkeys! They are waiting in your trunk.", "success")
end)

-- Command to release the monkeys
RegisterCommand('releasemonkeys', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, Config.VehicleCheckRadius, 0, 70)

    if DoesEntityExist(vehicle) then
        TriggerServerEvent('TrunkMonkeys:server:CheckHasMonkeys', NetworkGetNetworkIdFromEntity(vehicle))
        local timeout = 1000
        while not hasMonkeys and timeout > 0 do
            Wait(10)
            timeout = timeout - 10
        end

        if hasMonkeys then
            -- Check for disallowed vehicle classes
            local vehicleClass = GetVehicleClass(vehicle)
            if Config.DisallowedClasses[vehicleClass] then
                notification("You cannot release monkeys from this type of vehicle.", "error")
                return
            end

            notification("The monkeys are loose! Good luck.", "success")
            TriggerServerEvent('TrunkMonkeys:server:ReleaseMonkeys', GetVehicleNumberPlateText(vehicle), NetworkGetNetworkIdFromEntity(vehicle))
        else
            notification("You don't have any monkeys to release.", "error")
        end
        hasMonkeys = false
    else
        notification("You need to be near a vehicle to release the monkeys.", "error")
    end
end, false)

-- Event to trigger monkey release (for phone integration, etc.)
RegisterNetEvent('TrunkMonkeys:client:ReleaseMonkeys', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, Config.VehicleCheckRadius, 0, 70)

    if DoesEntityExist(vehicle) then
        TriggerServerEvent('TrunkMonkeys:server:CheckHasMonkeys', NetworkGetNetworkIdFromEntity(vehicle))
        local timeout = 1000
        while not hasMonkeys and timeout > 0 do
            Wait(10)
            timeout = timeout - 10
        end
        if hasMonkeys then
            local vehicleClass = GetVehicleClass(vehicle)
            if Config.DisallowedClasses[vehicleClass] then
                notification("You cannot release monkeys from this type of vehicle.", "error")
                return
            end

            notification("The monkeys are loose! Good luck.", "success")
            TriggerServerEvent('TrunkMonkeys:server:ReleaseMonkeys', GetVehicleNumberPlateText(vehicle), NetworkGetNetworkIdFromEntity(vehicle))
        else
            notification("You don't have any monkeys to release.", "error")
        end
        hasMonkeys = false
    else
        notification("You need to be near a vehicle to release the monkeys.", "error")
    end
end)

RegisterNetEvent('TrunkMonkeys:client:SpawnMonkeys', function(vehicleNetId, otherPlayers)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then return end

    local trunkOffset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.5, 0.5) -- Position behind the trunk

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
            SetPedRelationshipGroupHash(monkey, GetHashKey("hates_player"))

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
                    local targetPlayer = NetworkGetPlayerIndexFromPed(targetEntity)
                    if targetPlayer then
                        TriggerServerEvent('TrunkMonkeys:server:GetPlayerJob', GetPlayerServerId(targetPlayer))
                        local timeout = 1000
                        while not playerJob and timeout > 0 do
                            Wait(10)
                            timeout = timeout - 10
                        end
                        if playerJob and not Config.OnDutyJobs[playerJob] then
                            TaskCombatPed(monkey, targetEntity, 0, 16)
                        end
                        playerJob = nil
                    else
                        TaskCombatPed(monkey, targetEntity, 0, 16)
                    end
                else
                    -- No target, find the nearest player
                    local closestPlayer = nil
                    local closestDistance = -1

                    for _, player in ipairs(otherPlayers) do
                        local targetPed = GetPlayerPed(tonumber(player))
                        if DoesEntityExist(targetPed) then
                            TriggerServerEvent('TrunkMonkeys:server:GetPlayerJob', GetPlayerServerId(tonumber(player)))
                            local timeout = 1000
                            while not playerJob and timeout > 0 do
                                Wait(10)
                                timeout = timeout - 10
                            end
                            if playerJob and not Config.OnDutyJobs[playerJob] then
                                local distance = #(GetEntityCoords(targetPed) - GetEntityCoords(monkey))
                                if closestDistance == -1 or distance < closestDistance then
                                    closestPlayer = targetPed
                                    closestDistance = distance
                                end
                            end
                            playerJob = nil
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

            -- Monkey lifespan
            Wait(Config.MonkeyMaxLifespan)
            if DoesEntityExist(monkey) then
                DeleteEntity(monkey)
            end
        end)
    end
end)

RegisterNetEvent('TrunkMonkeys:client:ReceivePlayerJob', function(job)
    playerJob = job
end)

RegisterNetEvent('TrunkMonkeys:client:ReceiveHasMonkeys', function(hasMonkeysResult)
    hasMonkeys = hasMonkeysResult
end)

RegisterNUICallback('ReleaseMonkeys', function(data, cb)
    TriggerEvent('TrunkMonkeys:client:ReleaseMonkeys')
    cb('ok')
end)
