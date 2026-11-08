# me-capacity

Free space on the storage cells in ME Drives, in bytes and types. The ME network tells OC nothing about bytes,
but a transposer next to an ME Drive sees the cells, and OC adds their bytes and types. Warns when the cells
get full.

## Usage

```lua
local addons = require("addons.core")
local capacity = addons.load("me-capacity")

local space = capacity.read()
-- {totalBytes, usedBytes, freeBytes, fraction, types, totalTypes, cells, unknown, drives}
capacity.start()          -- reads every intervalSeconds, logs at warnPercent
capacity.stop()
```

`scan()` lists the drives it reads. Put a transposer against each ME Drive (one transposer can touch up to six).
With `drives` empty every side of every transposer is checked, so other inventories next to transposers are
read too; list the drives if that is a lot.

Only item cells report bytes. Fluid cells are counted in `unknown`. If no cell shows bytes, the server has
OpenComputers' item stack inspection (`allowItemStackInspection`) turned off.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `drives` | `{}` | `{{transposer = "1a2b", side = "north"}, ...}`; empty finds every drive |
| `warnPercent` | `90` | Warn when the cells are this full |
| `intervalSeconds` | `60` | How often `start()` reads |

## Components

`transposer` next to each ME Drive.

## Changelog

- 1.0.0 (2026-11-08): first version.
