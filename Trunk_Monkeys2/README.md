# QBCore Trunk Monkeys

Unleash chaos with Trunk Monkeys! This script for FiveM QBCore allows players to buy a "batch" of angry monkeys from a shady NPC, store them in the trunk of their vehicle, and release them on command to attack nearby hostiles or targeted players.

## Features

- **NPC Vendor:** Purchase monkeys from a configurable NPC at a set price.
- **Vehicle Storage:** Monkeys are stored in the trunk of any valid vehicle (cars, trucks, vans, etc.).
- **Attack on Command:** Release the monkeys to attack the nearest hostile player or the player you are currently targeting.
- **Configurable:** Easily change the NPC model, location, monkey price, number of monkeys, and more via the `config.lua` file.
- **QBCore Integration:** Built for the QBCore framework, utilizing its notification and payment systems.

## Dependencies

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-target](https://github.com/qbcore-framework/qb-target)

## Installation

1.  **Download the Script:** Download the `Trunk_Monkeys2` folder.
2.  **Add to Your Resources:** Place the `Trunk_Monkeys2` folder into your server's `resources` directory.
3.  **Ensure the Resource:** Add `ensure Trunk_Monkeys2` to your `server.cfg` file, making sure it comes after `qb-core` and `qb-target`.
4.  **Restart Your Server:** Restart your FiveM server, and the script will be active.

## How to Use

1.  **Find the NPC:** Go to the location configured in `config.lua`.
2.  **Buy the Monkeys:** Target the NPC and select the option to buy attack monkeys. You must be standing near a valid vehicle that you own.
3.  **Release the Monkeys:** Once the monkeys are in your trunk, you can release them in one of two ways:
    *   Use the `/releasemonkeys` command in chat.
    *   (Advanced) Integrate the `TrunkMonkeys:client:ReleaseMonkeys` event into a phone app or another trigger for a more seamless experience.

The monkeys will jump out of the trunk and attack the nearest hostile player or the player you are aiming at. Enjoy the chaos!
