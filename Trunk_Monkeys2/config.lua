Config = {}

-- [[ NPC Configuration ]]
-- You can find other models here: https://docs.fivem.net/docs/game-references/ped-models/
Config.NPCModel = 's_m_y_shop_01' -- This is a generic shopkeeper model
Config.NPCLocation = {
coords = vector3(3533.89, 3726.43, 36.45), -- Location next to Humane Labs
heading = 180.0
}

-- [[ Monkey Configuration ]]
Config.MonkeyPrice = 15000 -- Cost per "batch" of monkeys
Config.MonkeyModel = 'a_c_chimp' -- The in-game monkey model
Config.MonkeyCount = 3 -- How many monkeys are released
Config.MonkeySearchRadius = 30.0 -- How far (in meters) the monkeys will look for a target
Config.MonkeyMaxLifespan = 60000 -- How long (in ms) monkeys will stay before running off (60 seconds)
Config.VehicleCheckRadius = 6.0 -- How close you must be to your vehicle to buy or release monkeys

-- List of vehicle classes that are NOT allowed to store monkeys
Config.DisallowedClasses = {
[8] = true, -- Boats
[13] = true, -- Cycles
[15] = true, -- Helicopters
[16] = true, -- Planes
[21] = true, -- Trains
}

-- List of jobs that are considered "on-duty" and cannot be targeted by monkeys
Config.OnDutyJobs = {
    ['police'] = true,
    ['ems'] = true,
    ['fire'] = true,
}
