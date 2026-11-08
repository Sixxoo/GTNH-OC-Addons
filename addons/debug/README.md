# debug

Tools while writing a program: readable dumps of any value, the connected components, memory left, the signals that arrive, and errors with a traceback instead of lost ones.

## Usage

```lua
local addons = require("addons.core")
local dbg = addons.load("debug")

print(dbg.dump(component.me_interface.getCpus()))
dbg.log("levels", levels)                 -- to event-log at debug level
for _, c in ipairs(dbg.components()) do print(c.type, c.address) end
dbg.memory()                              -- {free, total, used, percent}
local signals = dbg.record(10, "^touch")  -- what arrives in 10 s (blocks)
dbg.trace(riskyFunction, arg)             -- logs the error with its traceback
```

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `depth` | `4` | How deep `dump()` goes into tables |

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version.
