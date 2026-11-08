# screen

Shows whole frames on the screen without flicker: each frame is a list of lines with colour codes, and only the
rows that changed since the last frame are drawn (into a GPU buffer, then copied). Fits the resolution to the
screen's shape and binds the screen again when it comes back after leaving the network.

## Usage

```lua
local addons = require("addons.core")
local screen = addons.load("screen")

local width, height = screen.open()          -- 35 rows; a 5x3 screen gives 117 x 35
screen.show(lines)                           -- lines[y]: text with &0xRRGGBB; (text) and &&0xRRGGBB; (background)
screen.close()                               -- largest resolution, cleared, when the program ends
```

| Function | What it does |
|---|---|
| `open(rows?)` | Sets the resolution for `rows` (default: setting `rows`), returns width and height |
| `show(lines)` | Draws the rows that changed, returns how many |
| `redraw()` | Draws every row with the next frame |
| `size()` | Width and height in use |
| `fit(rows)` | Width and height that fill the screen at `rows`, without setting them |
| `ensureScreen()` | Binds a lost screen again (`show` does this itself) |
| `close()` | Largest resolution, cleared |

[neon-ui](../neon-ui) makes such lines from cards, bars and text.

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `rows` | `35` | Rows used; the width follows from the screen's shape |
| `minWidth` | `80` | Narrowest width in characters |
| `fullRedrawSeconds` | `60` | Seconds between frames that draw every row |

## Components

`gpu`, `screen`. A tier 3 GPU and screen give up to 160 x 50.

## Changelog

- 1.0.0 (2026-11-08): first version, from Water Line Control.
