# tabs

Pages on one screen. A tab row in the neon style (the open tab as a filled label, the others with their number),
switched with Tab / Shift+Tab, the left and right arrows, the number keys or a touch on the row.

## Usage

```lua
local addons = require("addons.core")
local tabs = addons.load("tabs")

local pages = tabs.new({{id = "overview", title = "OVERVIEW"}, {id = "stats", title = "STATISTICS"}, {id = "log", title = "LOG"}})
pages:listen(function (id) redraw() end)   -- keys and touches until pages:stop()

-- when drawing
pages:draw(cv, 16, 2)                      -- the row, e.g. on the header line
if pages:current() == "stats" then drawStats(cv) end
```

| Function | What it does |
|---|---|
| `tabs.new(pages)` | A tab row: `{{id, title}, ...}` |
| `:current()` / `:index()` | Id / number of the open tab |
| `:select(id or n)`, `:next()`, `:prev()` | Open a tab, true when it changed |
| `:draw(cv, x, y, bg?)` | Draw the row on a `neon-ui` canvas (also where touches hit) |
| `:width()` | Width of the row in cells |
| `:key(char, code)` / `:touch(x, y)` | Handle a key or touch yourself, true when it changed |
| `:listen(onChange)` / `:stop()` | Listen to `key_down` and `touch` |

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `arrows` | `true` | Left and right arrows switch tabs (turn off if the program uses them) |
| `numbers` | `true` | Number keys 1-9 open a tab |

## Components

None (keyboard and screen of the program).

## Changelog

- 1.0.0 (2026-11-08): first version.
