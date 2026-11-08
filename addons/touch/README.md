# touch

Buttons and touch areas on the screen. Draw buttons while you draw a frame, then a touch tells which one was hit.
Areas are set again with every frame (`clear()`, then draw), so they always match what is shown.

## Usage

```lua
local addons = require("addons.core")
local touch = addons.load("touch")
local panel = touch.new()

-- while drawing a frame
panel:clear()
panel:button(cv, 2, 30, "START", "start")
panel:button(cv, 12, 30, "STOP", "stop", {active = running, color = ui.colors.red})
panel:area(1, 3, 40, 10, "units")        -- an area without drawing

panel:listen(function (id, x, y, button, player) ... end)
panel:stop()
```

`hit(x, y)` gives the area at a cell, `press(x, y)` the same but ignores a second touch within `repeatSeconds`.
A disabled button is drawn grey and can't be touched.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `repeatSeconds` | `0.3` | A second touch on the same button within this time is ignored |

## Components

`screen` (touch works on tier 2 and 3 screens).

## Changelog

- 1.0.0 (2026-11-08): first version.
