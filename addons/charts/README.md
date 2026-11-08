# charts

Charts on a `neon-ui` canvas: columns with labels under them, a one-row sparkline, and horizontal bars.

## Usage

```lua
local addons = require("addons.core")
local charts = addons.load("charts")

charts.columns(cv, 2, 20, 80, 12, cyclesPerHour, {labels = hourLabels, labelEvery = 3, values = true, lastColor = ui.colors.neon})
charts.sparkline(cv, 2, 5, 30, stockHistory)            -- ▁▂▃▅▇ in one row
charts.bars(cv, 2, 8, 50, {{label = "Iron", value = 120}, {label = "Gold", value = 80, text = "80/h"}})
```

| Function | What it draws |
|---|---|
| `columns(cv, x, y, w, h, values, options?)` | One column per value, oldest left; options `max`, `color`, `lastColor`, `labels`, `labelEvery`, `values`, `gap` |
| `sparkline(cv, x, y, w, values, options?)` | One row of eighth blocks between the lowest and highest value; options `min`, `max`, `color` |
| `bars(cv, x, y, w, items, options?)` | Label, bar and value per row; options `max`, `labelWidth`, `valueWidth` |

`nil` values leave a gap. Stacked full blocks join into solid columns in the OpenComputers font.

## Settings

None.

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version.
