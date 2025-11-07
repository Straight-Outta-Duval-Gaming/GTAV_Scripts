local isSpawningMonkeys = false -- Debounce to prevent spam

-- Standalone Notification Function
local function Notify(message, type)
    -- This is a basic chat message notification.
    -- Server owners can replace this with their preferred notification system.
    TriggerEvent('chat:addMessage', {
        color = { 255, 0, 0 },
        multiline = true,
        args = { "[TrunkMonkeys]", message }
    })
end

-- [[ Zone Interaction ]]
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local distance = #(coords - Config.PurchaseZone.coords)

        if distance < Config.PurchaseZone.radius and IsPedOnFoot(playerPed) then
            SetTextComponentFormat("STRING")
            AddTextComponentString("Press ~INPUT_CONTEXT~ to contact the monkey dealer.")
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)

            if IsControlJustReleased(0, 38) then -- 'E' Key
                TriggerEvent('TrunkMonkeys:client:AttemptPurchase')
            end
        end
    end
end)

-- [[ Purchase Logic ]]
RegisterNetEvent('TrunkMonkeys:client:AttemptPurchase', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, Config.VehicleCheckRadius, 0, 70)
    if not DoesEntityExist(vehicle) then
        Notify("You must be near a vehicle to buy monkeys.", "error")
        return
    end

    local class = GetVehicleClass(vehicle)
    if Config.DisallowedClasses[class] then
        Notify("Monkeys can't be stored in this type of vehicle.", "error")
        return
    end

    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    TriggerServerEvent('TrunkMonkeys:server:BuyMonkeys', vehiclePlate)
end)

-- [[ Release Logic ]]
RegisterNetEvent('TrunkMonkeys:client:ReleaseMonkeys', function()
    if isSpawningMonkeys then return end -- Stop spam

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, Config.VehicleCheckRadius, 0, 70)
    if not DoesEntityExist(vehicle) then
        Notify("You are not near a valid vehicle.", "error")
        return
    end

    isSpawningMonkeys = true
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    TriggerServerEvent('TrunkMonkeys:server:ReleaseMonkeys', VehToNet(vehicle), vehiclePlate)
end)

RegisterNetEvent('TrunkMonkeys:client:SpawnMonkeys', function(vehicleNetId, playerData)
    local vehicle = NetToVeh(vehicleNetId)
    if not DoesEntityExist(vehicle) then
        isSpawningMonkeys = false
        return
    end

    SetVehicleDoorOpen(vehicle, 5, false, false)

    CreateThread(function()
        Wait(1000) -- Wait for trunk to open

        RequestModel(Config.MonkeyModel)
        while not HasModelLoaded(Config.MonkeyModel) do
            Wait(100)
        end

        local playerPed = PlayerPedId()
        local trunkBone = GetEntityBoneIndexByName(vehicle, 'trunk')
        if trunkBone == -1 then
            Notify("This vehicle does not have a trunk.", "error")
            isSpawningMonkeys = false
            return
        end
        local spawnCoords = GetWorldPositionOfEntityBone(vehicle, trunkBone)
        local spawnedMonkeys = {}

        for i = 1, Config.MonkeyCount do
            local monkey = CreatePed(4, Config.MonkeyModel, spawnCoords, GetEntityHeading(playerPed), true, true)
            SetPedRelationshipGroupHash(monkey, GetHashKey("player"))
            SetPedCombatAttributes(monkey, 46, true)
            SetPedFleeAttributes(monkey, 0, false)
            SetEntityAsNoLongerNeeded(monkey)
            table.insert(spawnedMonkeys, monkey)
        end

        SetModelAsNoLongerNeeded(Config.MonkeyModel)

        for _, monkey in pairs(spawnedMonkeys) do
            -- Find a target
            local targeted, targetEntity = GetPlayerTargetEntity(PlayerId())
            if targeted and IsPed(targetEntity) then
                local isPlayer, player = IsPedAPlayer(targetEntity)
                if not isPlayer or (isPlayer and not Config.OnDutyJobs[playerData[tostring(player)]]) then
                    TaskCombatPed(monkey, targetEntity, 0, 16)
                end
            else
                -- If no aimed target, find a random ped (excluding players for simplicity in standalone)
                local peds = GetGamePool('CPed')
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

        isSpawningMonkeys = false

        -- Manage the monkeys' lifecycle
        CreateThread(function()
            local startTime = GetGameTimer()
            local lastCombatTime = GetGameTimer()
            local monkeysAreActive = true
            while monkeysAreActive do
                Wait(1000)
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

RegisterNetEvent('TrunkMonkeys:client:Notify', function(message, type)
    Notify(message, type)
end)

RegisterCommand('releasemonkeys', function()
    TriggerEvent('TrunkMonkeys:client:ReleaseMonkeys')
end, false)
