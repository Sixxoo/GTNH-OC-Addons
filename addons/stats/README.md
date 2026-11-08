# stats

Statistics that survive restarts. Counters (cycles, crafts) keep a total and a sum per hour, readings
(a stock, power) keep last, min, max and average per hour. History is kept for `keepHours` by real time and
saved to a small file. Uptime counts this run and all runs together.

## Usage

```lua
local addons = require("addons.core")
local stats = addons.load("stats")

stats.start()                       -- loads stats.dat, saves every saveSeconds and on stop()
stats.add("cycles")                 -- counter
stats.record("water.t1", 31500000)  -- reading

stats.total("cycles")               -- all time
stats.last("cycles", 24)            -- last 24 hours
stats.rate("cycles", 24)            -- per hour, over the time the program ran
stats.reading("water.t1", 24)       -- {last, min, max, avg, first}
stats.hours("cycles", 24)           -- 24 values, oldest first, for a chart
stats.uptime()                      -- {session, total, since}
stats.stop()
```

`save()` / `load()` by hand, `reset(name?)` forgets one entry or everything.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `filePath` | `"stats.dat"` | File in the program folder; `""` keeps them only while running |
| `keepHours` | `48` | Hours of history kept |
| `saveSeconds` | `300` | How often `start()` saves |

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version.
