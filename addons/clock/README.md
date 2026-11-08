# clock

Real time with a time zone. OpenComputers has no real clock: `os.time()` is game time (72x faster) and
`computer.uptime()` counts world ticks, which slow down with lag. This addon writes a small file and reads its
modification time, and counts on from the uptime in between, so calling it every frame costs nothing.

## Usage

```lua
local addons = require("addons.core")
local clock = addons.load("clock")

clock.format("%H:%M:%S")       -- "19:30:05"
local started = clock.now()    -- seconds since 1970 in your time zone
clock.since(started)           -- seconds passed
```

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `timeZone` | `0` | Hours from UTC: `1` for Prague in winter, `2` in summer |
| `readSeconds` | `30` | Seconds between reads of the real clock |
| `tmpFile` | `/tmp/clock.tmp` | File written to read the time |

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version, from Water Line Control.
