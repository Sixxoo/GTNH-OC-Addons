# power

The computer's own energy. Warns when it gets low, pushes `power_critical` before it runs out (so a program can switch machines to a safe state first) and estimates the time left while it drains. It also remembers when the program last ran: after a restart it tells when the computer went off without the program stopping, with how much energy it had then and for how long it was off.

## Usage

```lua
local addons = require("addons.core")
local power = addons.load("power")

power.start()      -- logs "The computer stopped unexpectedly at 08.11. 20:31 (energy 3%, likely out of power), off for about 4 min"
power.read()       -- {energy, max, fraction, perSecond, secondsLeft}
power.report()     -- what start() found, or nil
power.stop()       -- a clean stop: nothing is reported next time
```

Signals: `power_state` (state, fraction) on every change, `power_critical` (fraction), and `alert_raise` / `alert_clear`
for the `alerts` addon. A stop with energy near zero is reported as "out of power", otherwise as power, a crash or the chunk unloading.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `lowPercent` | `25` | Warn under this percent |
| `criticalPercent` | `10` | Critical under this percent |
| `intervalSeconds` | `10` | How often `start()` checks |
| `seenFile` | `".power-seen"` | File that remembers the last run; `""` = off |

## Components

None (the computer itself).

## Changelog

- 1.0.0 (2026-11-08): first version.
