# big-font

Big text, five rows high, for numbers and short words you read from across the room. Digits, A-Z and `. , : % + - / ! ?`.

## Usage

```lua
local addons = require("addons.core")
local big = addons.load("big-font")

big.draw(cv, 3, 5, "98%", ui.colors.green)
big.center(cv, 1, 12, cv.width, "12:45")
big.width("1.2M")                       -- cells it needs
```

Lower case is drawn upper case; unknown characters as a space. One empty column between letters.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `char` | `"█"` | Character the big letters are drawn with |

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version.
