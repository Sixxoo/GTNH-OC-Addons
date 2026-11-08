# Addon format

Every addon is built the same way, so the release workflow can bundle it into a program,
resolve what it needs, and list it in the catalog.

## Folder

```
addons/<name>/
  addon.lua      -- what the addon is (required)
  init.lua       -- the code, returned by require("addons.<name>") (required)
  README.md      -- how to use it, its settings and its changelog (required)
  *.lua, lib/    -- more code, if the addon needs it (optional)
  tests/         -- tests, never bundled into a program (optional)
```

- `<name>` is lowercase with dashes: `neon-ui`, `gt-machine`. Folders starting with `_` (like `_template`) are not addons.
- In a program the addon lands in `/home/addons/<name>/`, so code loads it with `require("addons.<name>")`.

## addon.lua

A plain Lua table, read without running anything else:

```lua
return {
  name = "discord",                       -- same as the folder
  version = "1.1.0",                      -- MAJOR.MINOR.PATCH, see Versions
  description = "Alerts to a Discord channel with pings and reminders", -- one line, English
  requires = {"clock@1"},                 -- other addons it needs: "<name>@<major>" or "<name>@<major>.<minor>"
  components = {"internet"},              -- OC components it needs, for the catalog and wiring checks
  settings = {                            -- what it reads from the shared /home/addons.cfg
    webhookUrl = {default = "", description = "Channel > Integrations > Webhooks > Copy URL. Empty is off"},
    mention = {default = "", description = 'Pinged on red messages: "<@user id>" or "<@&role id>"'},
  },
}
```

| Field | Required | Meaning |
|---|---|---|
| `name` | yes | Same as the folder name |
| `version` | yes | `MAJOR.MINOR.PATCH` |
| `description` | yes | One line in English, shown in the catalog |
| `requires` | no | Addons it needs, by major version (`"clock@1"`) or a lowest minor (`"clock@1.2"`) |
| `components` | no | OC component types it needs (`"gpu"`, `"internet"`, `"me_interface"`, ...) |
| `settings` | no | Settings in `/home/addons.cfg`, each with a `default` and a `description` |

## init.lua

```lua
local M = {}

-- Called by the loader with the addon's settings: defaults from addon.lua,
-- then /home/addons.cfg, then what the program passes. Optional.
function M.setup(settings)
  M.settings = settings
end

-- Optional: start and stop anything that keeps running (listeners, timers, threads).
function M.start() end
function M.stop() end

return M
```

Rules:

1. **No side effects on `require`.** Loading an addon never starts listeners, timers or threads, and never touches components.
   Work like that goes in `start()`, and `stop()` undoes all of it: in OpenOS listeners outlive the program that made them.
2. **No globals.** Everything is local or in the returned table.
3. **Other addons only through `require("addons.<name>")`**, and only those listed in `requires`. An addon never loads program code.
4. **Errors name the addon**: `error("[discord] webhook rejected: 404")`.
5. **Screen text uses one-cell characters only.**
6. **Settings come from `setup`**, never read from files directly, so programs can override them and tests can pass them in.

## Versions

| Change | Bump | Example | Programs get it |
|---|---|---|---|
| A fix, nothing else changes | PATCH | 1.2.0 -> 1.2.1 | Automatically |
| Something new that keeps the old working (a new option, a new function) | MINOR | 1.2.1 -> 1.3.0 | Automatically |
| Anything that can break a program (renamed or removed function, changed meaning) | MAJOR | 1.3.0 -> 2.0.0 | Only after the program is updated |

A program asking for `"neon-ui@1"` gets the newest 1.x. `"neon-ui@1.3"` means 1.3 or newer, still 1.x.

## In a program

The program lists its addons in `addons.lua`:

```lua
return {
  "neon-ui@1",
  "clock@1",
  "discord@1",
}
```

The release workflow copies those addons (and everything they `require`, and `core`) into the program's archive.
In the code:

```lua
local addons = require("addons.core")
local discord = addons.load("discord", {name = "Water Line"}) -- the program's own overrides, optional
discord.start()
```

## Shared settings: /home/addons.cfg

One file per OC computer, used by every program on it. One section per addon, named like the addon:

```lua
return {
  clock = {timeZone = 1},
  discord = {webhookUrl = "https://discord.com/api/webhooks/...", mention = "<@123456789>"},
}
```

Missing sections and settings use the defaults from `addon.lua`. The installer asks for the settings of the addons
a program uses the first time, and later only for new ones.

## README.md of an addon

Sections, in this order: what it does (a sentence or two), **Usage** (a short example), **Settings** (table of
`settings`), **Components**, **Changelog** (newest first: version, date, one line per change).

## Checks

`tools/check_addons.py` checks every addon: the fields of `addon.lua`, that `requires` point at existing addons and
versions, no loops between addons, and that the Lua files compile. It runs on every push.
