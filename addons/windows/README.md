# windows

Pop-up windows over the screen: messages and yes / no questions with buttons, answered by key or touch. The newest window is on top and takes the keys and touches.

## Usage

```lua
local addons = require("addons.core")
local windows = addons.load("windows")
local wm = windows.new()

wm:confirm("SWITCH OFF?", {"The plant stops after this cycle."}, function (yes) if yes then stop() end end)
wm:message("SAVED", "config.lua was saved")
wm:open({title = "MODE", lines = {"Pick a mode"}, buttons = {{key = "1", label = "1 single", id = "single"}, {key = "2", label = "2 multi", id = "multi"}},
  onClose = function (id) ... end})

-- drawing: the page first, then
wm:draw(cv)
-- input: windows first
if not wm:key(char, code) then handleKey(char, code) end
if not wm:touch(x, y) then handleTouch(x, y) end
```

Enter presses an OK button, Esc the last button. `isOpen()`, `top()`, `close(id)`.

## Settings

None.

## Components

None (keyboard and screen of the program).

## Changelog

- 1.0.0 (2026-11-08): first version.
