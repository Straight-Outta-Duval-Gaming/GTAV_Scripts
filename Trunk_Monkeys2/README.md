# TrunkMonkeys2

This script allows players to buy a "batch" of angry monkeys from a shady NPC, store them in the trunk of their vehicle, and release them on command to attack nearby players.

## Features

- **NPC Vendor:** Purchase monkeys from a configurable NPC at a set price.
- **Vehicle Storage:** Monkeys are stored in the trunk of any valid vehicle (cars, trucks, vans, etc.).
- **Attack on Command:** Release the monkeys to attack the nearest player.
- **Configurable:** Easily change the NPC model, location, monkey price, number of monkeys, and more via the `config.lua` file.
- **Standalone:** This script is standalone and does not require any specific framework.

## Installation

1.  **Download the Script:** Download the `TrunkMonkeys2` folder.
2.  **Add to Your Resources:** Place the `TrunkMonkeys2` folder into your server's `resources` directory.
3.  **Ensure the Resource:** Add `ensure TrunkMonkeys2` to your `server.cfg` file.
4.  **Restart Your Server:** Restart your FiveM server, and the script will be active.

## How to Use

1.  **Find the NPC:** Go to Humane Labs (or wherever you've configured the NPC to be).
2.  **Buy the Monkeys:** Look at the NPC and press 'E' to buy the monkeys. You must be standing near a valid vehicle.
3.  **Release the Monkeys:** Once the monkeys are in your trunk, you can release them in one of two ways:
    *   Use the `/releasemonkeys` command in chat.
    *   Integrate the `TrunkMonkeys:client:ReleaseMonkeys` event into a phone app or another trigger for a more seamless experience.

## Phone Integration

To integrate the monkey release feature into your phone, you will need to trigger the `TrunkMonkeys:client:ReleaseMonkeys` event from your phone's code. Here is an example of how you might do this in a few popular phone systems:

### qb-phone

In your `qb-phone`'s `html/js/app.js` file, you would add a button to one of your apps. The JavaScript for that button would use `$.post` to trigger the event:

```javascript
$.post('https://TrunkMonkeys2/ReleaseMonkeys', JSON.stringify({}));
```

Then, in `TrunkMonkeys2/client.lua`, you would need this:

```lua
RegisterNUICallback('ReleaseMonkeys', function(data, cb)
    TriggerEvent('TrunkMonkeys:client:ReleaseMonkeys')
    cb('ok')
end)
```

### gksphone

In `gksphone`, you would add an app with a button that triggers a client event. In the `client` script of your new app, you would have:

```lua
TriggerEvent('TrunkMonkeys:client:ReleaseMonkeys')
```

### Other Phone Systems

Most phone systems have a similar way of triggering client-side events. You will need to consult the documentation for your specific phone system to see how to trigger the `TrunkMonkeys:client:ReleaseMonkeys` event.
