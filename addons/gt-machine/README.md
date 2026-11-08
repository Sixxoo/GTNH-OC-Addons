# gt-machine

GregTech machines as an adapter shows them (`gt_machine`): find them by name, read their state, switch them on and
off, and read sensor values by key. GTNH 2.9 gives sensor lines as raw translation keys with arguments, older
versions as English text; reading by a piece of the key or text keeps working where line numbers break.

## Usage

```lua
local addons = require("addons.core")
local gt = addons.load("gt-machine")

local plant = assert(gt.find("multimachine.purificationplant"))
local state = gt.state(plant)          -- {working, progress, maxProgress, seconds, fraction, allowed}
gt.allow(plant, false)                 -- stops after the current recipe or cycle

local stored = gt.read(lsc, "eu_stored")        -- 4424885923 from "kekztech...eu_stored\\4,424,885,923"
local line = gt.line(unit, "Success")           -- {key, args, text}
gt.number("98,5%")                              -- 98.5
```

| Function | What it does |
|---|---|
| `find(pattern)` | The one machine whose name matches, or nil and why |
| `findAll(pattern)` | Every machine that matches |
| `state(proxy)` | Working, progress, seconds left, allowed |
| `allow(proxy, on)` | Allow or stop work |
| `sensor(proxy)` | Sensor lines as `{key, args, text}` |
| `line(proxy, piece)` | First sensor line whose key or text contains the piece |
| `read(proxy, piece, n?)` | Number from that line: argument `n` (default 1) or the number in its text |
| `number(text)` | Number from text with any thousands separator; 1-2 digits after the last separator are decimals |

An adapter touching a controller shows it as `gt_machine`; with an MFU inside, it shows the linked block instead
(shift-right-click the controller with the MFU before putting it in, range 16 blocks).

## Settings

None.

## Components

`gt_machine` (an adapter on a GT controller, or with a linked MFU).

## Changelog

- 1.0.0 (2026-11-08): first version, from Water Line Control; sensor values by key instead of line number.
