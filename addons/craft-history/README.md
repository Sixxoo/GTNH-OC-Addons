# craft-history

Keeps the finished crafting jobs that `cpu-monitor` sees in a small file: the newest jobs and totals per item,
also after a restart.

## Usage

```lua
local addons = require("addons.core")
local history = addons.load("craft-history")

history.start()           -- loads the file, records every ae2_job_done (start cpu-monitor too)
history.recent(5)         -- {{time, cpu, label, size, seconds}}, newest first
history.stats()           -- {{label, jobs, items, seconds}}, most crafted first
history.stop()
```

`add(job)` records a job by hand, `load()` reads the file, `clear()` empties the memory (not the file).
The file has one job per line: `time<TAB>cpu<TAB>size<TAB>seconds<TAB>label`.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `filePath` | `"craft-history.log"` | File in the program folder; `""` keeps jobs only in memory |
| `fileMaxKb` | `32` | Size at which the file becomes `.old` and a new one starts |
| `keep` | `200` | Jobs kept in memory |

## Components

None (the jobs come from `cpu-monitor`).

## Changelog

- 1.0.0 (2026-11-08): first version.
