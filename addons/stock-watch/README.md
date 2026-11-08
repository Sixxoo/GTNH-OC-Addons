# stock-watch

Watches items and fluids in the ME network against a minimum and an optional maximum. Gives rows for the
screen and logs when something runs low, runs out, is fine again or goes over its maximum.

## Usage

```lua
local addons = require("addons.core")
local watch = addons.load("stock-watch")
local me = assert(addons.load("ae2").find())

watch.start(me)                 -- checks settings.watch every intervalSeconds
for _, row in ipairs(watch.rows()) do
  -- row: {key, label, amount, min, max, state = "empty"|"low"|"ok"|"high", fraction}
end
watch.stop()
```

`check(proxy, list?)` checks once, `state(amount, min, max)` gives the state of one amount. When an entry
changes state it logs (through `event-log`) and pushes `stock_changed` (key, state, oldState, amount).

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `intervalSeconds` | `30` | How often `start()` checks |
| `watch` | `{}` | `{{what = "fluid:water", min = 1000000, max = 32000000, label = "Water"}, ...}`, keys as in `ae2` |
| `logChanges` | `true` | Log state changes |

## Components

`me_interface` or `me_controller`, through `ae2`.

## Changelog

- 1.0.0 (2026-11-08): first version.
