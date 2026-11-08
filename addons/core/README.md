# core

Loads addons and gives each one its settings. Every program gets it.

## Usage

```lua
local addons = require("addons.core")
local clock = addons.load("clock")                        -- settings from addon.lua and /home/addons.cfg
local discord = addons.load("discord", {name = "Meteor"}) -- the program overrides one setting
```

Settings are merged in this order, later wins: defaults in the addon's `addon.lua`, its section in
`/home/addons.cfg`, the table the program passes to `load`.

| Function | What it does |
|---|---|
| `load(name, overrides?)` | `require`s the addon, calls its `setup(settings)`, returns it. Already loaded and no overrides: returned as it is |
| `reload(name)` | Sets the addon up again from `/home/addons.cfg`, after it was edited |
| `settings(name, overrides?)` | The merged settings, without loading the addon |
| `info(name)` | The addon's `addon.lua` table |
| `sharedConfig()` | The table in `/home/addons.cfg` (empty if the file is missing) |
| `reloadConfig()` | Read `/home/addons.cfg` again on the next call, after it was edited |
| `warnings` | Problems found on the way: a broken `addons.cfg`, unknown settings |

A broken `/home/addons.cfg` never stops a program: it is ignored with a warning, and the defaults are used.

## Settings

None.

## Components

None.

## Changelog

- 1.1.0 (2026-11-08): `load` without overrides returns an addon that is already set up, so one addon loading another doesn't reset its settings; `reload`.
- 1.0.0 (2026-11-08): first version.
