# history

Values over a long time, kept small. Every value goes into each resolution: by default one point a minute for 2 hours, one per 15 minutes for 2 days and one per 6 hours for 30 days. A point keeps the average, lowest and highest value of its time. Saved to a file, by real time.

## Usage

```lua
local addons = require("addons.core")
local history = addons.load("history")

history.start()                          -- loads history.dat, saves every saveSeconds and on stop()
history.add("water.t3", 840000)          -- e.g. once a minute

local day = history.series("water.t3", 900, 96)    -- last 24 hours by 15 minutes
-- {values = {...averages, nil = nothing then}, low = {...}, high = {...}, times = {...}, seconds = 900}
history.names()
history.stop()
```

`series(name, resolution, n)` takes the seconds per point (`60`, `900`, `21600`) or the level number. Pairs well with
`charts.sparkline` and `charts.columns`. For counts per hour and all-time totals use `stats`.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `filePath` | `"history.dat"` | File in the program folder; `""` keeps it only while running |
| `levels` | `minute x120, 15 min x192, 6 h x120` | Resolutions: `{{seconds = 60, keep = 120}, ...}` |
| `saveSeconds` | `300` | How often `start()` saves |

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version.
