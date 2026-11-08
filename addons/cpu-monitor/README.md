# cpu-monitor

Crafting CPUs of the ME network: which are busy, what each crafts and for how long. While started it
follows the jobs, logs when one starts and ends, and tells other addons (`craft-history`).

## Usage

```lua
local addons = require("addons.core")
local cpus = addons.load("cpu-monitor")
local me = assert(addons.load("ae2").find())

cpus.start(me)
local now = cpus.last()   -- {cpus = {{name, busy, storage, coprocessors, label, size, seconds}}, busy, free, total}
cpus.stop()
```

`read(proxy)` looks once. `duration(seconds)` formats `2m 05s`. Signals: `ae2_job_started` (cpu, label, size)
and `ae2_job_done` (cpu, label, size, seconds). Jobs of players and other programs count too.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `intervalSeconds` | `5` | How often `start()` looks at the CPUs |
| `logJobs` | `true` | Log when a job starts and ends |

## Components

`me_interface` or `me_controller`, through `ae2`.

## Changelog

- 1.0.0 (2026-11-08): first version.
