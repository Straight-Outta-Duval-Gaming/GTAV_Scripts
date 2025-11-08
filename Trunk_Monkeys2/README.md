# QBCore Trunk Monkeys

Unleash chaos with Trunk Monkeys! This script for FiveM QBCore allows players to buy a "batch" of angry monkeys from a configurable purchase zone, store them in the trunk of their vehicle, and release them on command to attack nearby hostiles or targeted players.

## Features

- **Purchase Zone:** Buy monkeys by entering a configurable circular zone.
- **In-Vehicle Actions:** Purchase and release monkeys from the driver's seat of a stationary vehicle.
- **Vehicle Storage:** Monkeys are stored in the trunk of any valid vehicle (cars, trucks, vans, etc.).
- **Attack on Command:** Release the monkeys to attack the nearest hostile player or the player you are currently targeting.
- **Configurable:** Easily change the purchase zone location and radius, monkey price, number of monkeys, and more via the `config.lua` file.
- **QBCore Integration:** Built for the QBCore framework, utilizing its notification and payment systems.

## Dependencies

- [qb-core](https://github.com/qbcore-framework/qb-core)

## Installation

1.  **Download the Script:** Download the `Trunk_Monkeys2` folder.
2.  **Add to Your Resources:** Place the `Trunk_Monkeys2` folder into your server's `resources` directory.
3.  **Ensure the Resource:** Add `ensure Trunk_Monkeys2` to your `server.cfg` file, making sure it comes after `qb-core`.
4.  **Restart Your Server:** Restart your FiveM server, and the script will be active.

## How to Use

1.  **Find the Purchase Zone:** Go to the location configured in `config.lua`.
2.  **Buy the Monkeys:** Enter the zone on foot or in a vehicle. You will receive a prompt to press 'E' to buy. If you are in a vehicle, you must be the driver and the vehicle must be stationary.
3.  **Release the Monkeys:** Once the monkeys are in your trunk, you can release them in one of two ways:
    *   Use the `/remonk` command in chat. This can be done on foot near the trunk or from the driver's seat of a stationary vehicle.
    *   (Advanced) Integrate the `TrunkMonkeys:client:ReleaseMonkeys` event into a phone app or another trigger for a more seamless experience.

The monkeys will jump out of the trunk and attack the nearest hostile player or the player you are aiming at. Enjoy the chaos!
