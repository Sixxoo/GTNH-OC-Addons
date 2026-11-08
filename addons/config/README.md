# config

A program's own settings (`config.lua`): a schema says what each setting may be, mistakes are listed with the
setting's path and the values that would work, the file opens in the editor and is checked again, and an update
keeps the player's values.

## Usage

```lua
local addons = require("addons.core")
local cfg = addons.load("config")

local schema = cfg.table({
  mode = cfg.enum({"multiThread", "singleThread", "singleThreadBalancing"}),
  floorQty = cfg.number({min = 0, default = 0}),
  meInterfaceAddress = cfg.address(),
  t3 = cfg.table({
    enable = cfg.boolean(),
    transposerAddress = cfg.address({optional = true}),
    hatchSide = cfg.side({default = "up"}),
  }),
})

local config = cfg.load("/home/config.lua", schema)   -- errors list every mistake
local edited, problems = cfg.edit("/home/config.lua", schema)   -- opens the editor, nil + problems on mistakes
local merged, report = cfg.merge(oldText, newText)    -- the new file's layout with the player's values
```

A mistake reads like `t3.hatchSide: is "dwon", use "up", "down", "north", "south", "west", "east" or 0-5`.

| Field | Accepts | Options |
|---|---|---|
| `number` | a number | `min`, `max`, `integer` |
| `string` | text | `nonEmpty`, `pattern` |
| `boolean` | `true` / `false` | |
| `enum(values)` | one of the values, any case; gives the listed spelling | |
| `address` | a full component address | |
| `side` | `"up"`, `"down"`, `"north"`, `"south"`, `"west"`, `"east"` or 0-5; gives the number | |
| `color` | `0xRRGGBB` | |
| `table(fields)` | a table with these fields; unknown fields are warnings | |
| `list(item)` | a list of one kind | `min` |
| `map(value)` | any keys, values of one kind | |

Every field also takes `optional = true`, `default = value` (used when missing) and `check = function (value, root) return ok, message end`.

`merge(oldText, newText, rules)` keeps comments and layout of the new file. `rules.moved = {{from = "a.b", to = "c.d"}}`
carries values to a new place, `rules.whenMissing = {{pattern = "^x%.y$", value = 0, why = "..."}}` sets what a
missing setting gets instead of the new default. `describe(report)` gives lines for the player.

## Settings

None.

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version, from Water Line Control (config-manager and config-merger), simpler schema.
