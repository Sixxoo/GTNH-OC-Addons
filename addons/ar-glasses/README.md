# ar-glasses

Lines of text on the HUD of AR glasses, through an OpenGlasses glasses terminal (component `glasses`). Each line has a key; only what changed is sent, so the server isn't asked to remake widgets every update.

## Usage

```lua
local addons = require("addons.core")
local glasses = addons.load("ar-glasses")

glasses.set("water", "T3 water 840k", 0xFF2A3D)
glasses.set("power", "Power 72%", 0x2BE05A)
glasses.remove("power")
glasses.players()          -- who wears linked glasses
glasses.clear()
```

Every glasses call is guarded: if the terminal's API differs in your pack, that piece is skipped and the program keeps
running. Not tried in a world yet: if lines don't show, run `components glasses` and check the terminal is linked.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `x` | `4` | Left edge of the lines, HUD pixels |
| `y` | `4` | Top edge, HUD pixels |
| `lineHeight` | `10` | Pixels between lines |
| `scale` | `1` | Text size |
| `background` | `0.4` | Opacity of the box behind the lines (0 = none) |

## Components

`glasses` (an OpenGlasses glasses terminal).

## Changelog

- 1.0.0 (2026-11-08): first version.
