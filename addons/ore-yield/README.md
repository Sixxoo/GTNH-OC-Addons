# ore-yield

How fast items come into the ME network, per real hour: ores from Ore Drilling Plants, void miners, a meteor
ritual or anything else. Per item and in total, over a sliding window.

## Usage

```lua
local addons = require("addons.core")
local yield = addons.load("ore-yield")
local me = assert(addons.load("ae2").find())

yield.start(me)           -- a sample every intervalSeconds
local rates = yield.rates()
-- {rows = {{key, label, perHour, gained, amount}}, perHour = total, minutes = time covered}
yield.stop()
```

`sample(proxy)` takes one sample, `clear()` starts over. Each filter is one network read filtered by the network,
so a big network isn't scanned whole. Items used up count as negative rates (not in the total).

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `filters` | `{{name = "gregtech:gt.blockores"}}` | What counts, as `ae2` filters, e.g. `{label = "Raw Gold"}` |
| `windowMinutes` | `60` | Rates over this many minutes |
| `intervalSeconds` | `60` | How often `start()` samples |

## Components

`me_interface` or `me_controller`, through `ae2`.

## Changelog

- 1.0.0 (2026-11-08): first version.
