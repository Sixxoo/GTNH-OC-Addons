# profiler

Where a program spends its time and its component calls. `measure()` and `wrap()` time functions (CPU time of the computer), `proxy()` counts and times every call on a component, since every component call costs the server time.

## Usage

```lua
local addons = require("addons.core")
local profiler = addons.load("profiler")

local me = profiler.proxy(component.me_interface, "me")    -- use instead of the real proxy
draw = profiler.wrap("draw", draw)
profiler.measure("loop", step)

for _, line in ipairs(profiler.lines(10)) do print(line) end
-- NAME            CALLS   TOTAL ms   AVG ms   MAX ms
profiler.report("calls")       -- {{name, calls, total, avg, max}}
profiler.reset()
```

## Settings

None.

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version.
