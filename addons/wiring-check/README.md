# wiring-check

Checks at start that every component a config names is on the network. For a missing one it lists the components of that type nobody else in the list uses, so a replaced adapter with a new address is found at once, and `repair()` can write the new address into `config.lua`.

## Usage

```lua
local addons = require("addons.core")
local wiring = addons.load("wiring-check")

local list = {
  {name = "[QC] ME Interface", type = "me_interface", address = config.meInterfaceAddress},
  {name = "[T3] Transposer", type = "transposer", address = config.t3.transposerAddress},
}

local result = wiring.check(list)          -- {ok, missing, rows = {{name, type, address, found, candidates}}}
for _, line in ipairs(wiring.problems(result)) do print(line) end
-- [QC] ME Interface (me_interface 261af9d4) is missing; one unused me_interface: 0604d547-..., is that it?

wiring.repair(list, "config.lua", function (question) return askYesNo(question) end)
wiring.inventory()                          -- {me_interface = {...}, transposer = {...}, ...}
```

`fix(path, old, new)` replaces one quoted address in a file. Entries without an address are skipped.

## Settings

None.

## Components

Whatever the list names.

## Changelog

- 1.0.0 (2026-11-08): first version.
