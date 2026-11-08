# widgets

Ready-made neon pieces on top of `neon-ui`: a tile with one value, status lights, a table with aligned columns and a meter.

## Usage

```lua
local addons = require("addons.core")
local widgets = addons.load("widgets")

widgets.tile(cv, 1, 3, 20, 5, "CYCLES", "1 234", {sub = "today", color = ui.colors.neon})
widgets.status(cv, 22, 3, 30, {{label = "ME", state = "ok", text = "online"}, {label = "Power", state = "warning", text = "12%"}})
widgets.table(cv, 1, 9, 50, 10, {{title = "ITEM"}, {title = "AMOUNT", width = 10, align = "right"}}, rows)
widgets.meter(cv, 1, 20, 30, "Disks", 75, 100)
```

Status states: `ok` (green), `warning` (amber), `error` (red), `busy` (blue), `off` (grey).
Table cells are text or `{text, colour}`; columns without a width share the rest.

## Settings

None.

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version.
