# transposer

Finds where a fluid or an item is around a transposer (on every side except the hatch's) and moves it into the
hatch, which can be on any side. Copes with the OpenComputers quirks: `getTankCount` gives `nil` on a side without a
tank, `getFluidInTank` errors on a bad index, an empty tank has no name or amount.

## Usage

```lua
local addons = require("addons.core")
local tp = addons.load("transposer")
local proxy = require("component").proxy(config.t3.transposerAddress)
local hatch = "down"                                     -- the hatch is under the transposer

local found, missing = tp.findFluids(proxy, {"polyaluminiumchloride"}, {hatch})
if #missing > 0 then
  for _, line in ipairs(tp.describe(proxy)) do print(line) end   -- "up: polyaluminiumchloride 4000000", ...
end

local moved = tp.fill(proxy, found.polyaluminiumchloride, hatch, 900000)
```

| Function | What it does |
|---|---|
| `findFluids(proxy, names, ignore?)` | `name -> {side, tank, amount}` and the names not found |
| `findItems(proxy, labels, ignore?)` | `label -> {side, slot, size}` and the labels not found |
| `tanks(proxy, ignore?)` | Every tank: `{side, tank, name, amount, capacity}` |
| `describe(proxy)` | One line per side: what is there, for error messages |
| `moveFluid(proxy, from, hatchSide, amount)` | One transfer, returns what arrived |
| `fill(proxy, from, hatchSide, amount)` | Transfers until the amount arrived or nothing moves |
| `moveItems(proxy, from, hatchSide, count)` | Moves items, returns how many arrived |
| `side(value)`, `sideName(side)` | `"down"` -> 0, 1 -> `"up"` |

How much fluid one transfer moves depends on the Fluid Regulator the transposer was made with; for thousands of
litres per transfer use an LuV regulator or better.

## Settings

None.

## Components

`transposer`.

## Changelog

- 1.0.0 (2026-11-08): first version, from Water Line Control (component-discover and the T3 controller).
