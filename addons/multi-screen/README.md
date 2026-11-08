# multi-screen

Several screens from one computer. Each screen shows its own frames of coded lines (as `neon-ui` `canvas:lines()` gives them), only changed rows are drawn. With a GPU per screen each GPU keeps its screen; with fewer GPUs the first one is moved between screens (slower, but works).

## Usage

```lua
local addons = require("addons.core")
local ms = addons.load("multi-screen")

local list = ms.list()                 -- screen addresses, sorted
local w, h = ms.open(list[1], 35)      -- resolution from the screen's shape
ms.open(list[2], 20)

ms.show(list[1], mainCanvas:lines())
ms.show(list[2], statsCanvas:lines())
ms.close()
```

`size(address)`, `redraw(address?)`. Every screen and GPU counts towards the computer's component limit.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `rows` | `25` | Rows of a screen opened without rows |

## Components

`gpu` (one per screen is best) and `screen`.

## Changelog

- 1.0.0 (2026-11-08): first version.
