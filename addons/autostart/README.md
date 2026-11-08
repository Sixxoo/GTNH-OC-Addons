# autostart

Starts one program when the computer boots, and turns the computer on by redstone after a power loss.

OpenOS runs `/home/.shrc` when its shell starts; this addon keeps one line there, marked `# autostart`, and leaves
your other lines alone. Only one program can start this way, because it runs in the shell.
Wake on redstone needs a redstone card in the computer (a Redstone I/O block can't wake it). Wire a slow redstone
clock to the computer or rack, a pulse every 30 to 60 s, away from the screen.

## Usage

```lua
local addons = require("addons.core")
local autostart = addons.load("autostart")

autostart.enable("/home/water-line", "main")   -- replaces the program that started before
autostart.current()                             -- "/home/water-line", "main"
autostart.disable()

autostart.wakeIsOn()      -- true / false, nil without a redstone card
autostart.enableWake()    -- false without a redstone card
```

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `shrc` | `"/home/.shrc"` | File the shell runs when it starts |

## Components

`redstone` (a redstone card) for waking; starting at boot needs nothing.

## Changelog

- 1.0.0 (2026-11-08): first version, from Water Line Control's setup.
