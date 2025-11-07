# Standalone Trunk Monkeys

Unleash chaos with Trunk Monkeys! This standalone script for FiveM allows players to buy a "batch" of angry monkeys from a hidden location, store them in the trunk of their vehicle, and release them on command to attack nearby hostiles or targeted players.

## Features

- **Purchase Zone:** Purchase monkeys from a configurable location.
- **Vehicle Storage:** Monkeys are stored in the trunk of any valid vehicle (cars, trucks, vans, etc.).
- **Attack on Command:** Release the monkeys to attack the nearest hostile player or the player you are currently targeting.
- **Configurable:** Easily change the purchase location, monkey price, number of monkeys, and more via the `config.lua` file.
- **Standalone:** This script does not require any specific framework like ESX or QBCore.

## Installation

1.  **Download the Script:** Download the `Trunk_Monkeys2` folder.
2.  **Add to Your Resources:** Place the `Trunk_Monkeys2` folder into your server's `resources` directory.
3.  **Ensure the Resource:** Add `ensure Trunk_Monkeys2` to your `server.cfg` file.
4.  **Configure:** Open `server.lua` and replace the placeholder `RemoveMoney` function with your server's economy logic.
5.  **Restart Your Server:** Restart your FiveM server, and the script will be active.

## How to Use

1.  **Find the Location:** Go to the location configured in `config.lua`.
2.  **Buy the Monkeys:** Press 'E' to buy the monkeys. You must be standing near a valid vehicle.
3.  **Release the Monkeys:** Once you have purchased a set of monkeys, you can release them in one of two ways:
    *   Use the `/releasemonkeys` command in chat.
    *   (Advanced) Integrate the `TrunkMonkeys:client:ReleaseMonkeys` event into a phone app or another trigger for a more seamless experience.

The monkeys will jump out of the trunk and attack the nearest hostile ped or the player you are aiming at. Enjoy the chaos!
