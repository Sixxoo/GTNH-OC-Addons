# neon-ui

The neon style as building blocks: blue framed cards with red corners on near black, bars with a red slider,
label/value rows, a header and a footer. A program builds its own layout from them; the result is lines for
[screen](../screen).

## Usage

```lua
local addons = require("addons.core")
local ui = addons.load("neon-ui")
local screen = addons.load("screen")

local width, height = screen.open()
local cv = ui.canvas(width, height)
ui.header(cv, {clock = "12:00:00", title = "WATER LINE", by = "by Sixxo", status = "RUNNING", badge = "BALANCING"})
ui.card(cv, 1, 3, 40, 6, "CYCLE", {right = "RUNNING", rightColor = ui.colors.green})
ui.bar(cv, 3, 5, 36, 0.4, {color = ui.colors.yellow})
ui.row(cv, 3, 6, 36, "Next cycle", "T2", ui.colors.neon, ui.colors.card)
ui.footer(cv, {keys = {{"Q", "quit"}}, legend = {{"▶", "next cycle"}}})
screen.show(cv:lines())
```

| Piece | What it draws |
|---|---|
| `canvas(w, h)` | A grid to draw on: `put`, `fill`, `putCoded` (text with `&white;` codes), `lines()` |
| `card(cv, x, y, w, h, title, {right, rightColor, titleColor})` | Filled frame with a title and a value at the top right |
| `divider(cv, x, y, w)` | A line across a card, joined to the frame |
| `bar(cv, x, y, w, fraction, {color, track, slider, sliderColor, bg})` | Heavy line up to the fraction, light line after it, red slider |
| `row(cv, x, y, w, label, value, color, bg)` | Label left, value right |
| `badge(cv, x, y, text, color)` | Filled label |
| `header(cv, {clock, title, by, status, statusColor, badge, badgeColor, version})` | Rows 1 and 2 |
| `footer(cv, {keys, legend})` | Last row |
| `log(cv, x, y, w, h, title, lines, offset)` | A card with log lines and a scroll mark, returns the offset kept in range |
| `levelColor(value, steps, otherwise)` | Colour by thresholds: `{{below = 1e6, color = red}, ...}` |
| `fit`, `length`, `duration` | Text helpers |

Colours are in `ui.colors`: `bg card face alt neon red green amber yellow orange cyan text dim sub na track line`.

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `theme` | `{}` | Colours to change, e.g. `{neon = 0xFF2A3D}` for red frames |
| `corners` | `true` | Red corners on cards |

## Components

None (draws into a canvas; [screen](../screen) puts it on the screen).

## Changelog

- 1.0.0 (2026-11-08): first version, from Water Line Control.
