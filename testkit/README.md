# testkit

A fake OpenOS to test addons and programs without the game: components, events, timers, a world clock,
and a GPU that records every cell, so screens can be checked and saved as pictures.

```
pip install lupa pillow
python3 testkit/run.py                    # all tests in addons/*/tests and testkit/tests
python3 testkit/run.py --root ../my-prog  # tests of a program, with addons from this repo
```

## A test

`addons/<name>/tests/<something>_test.lua`:

```lua
local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()                                   -- event, component, computer, sides, ... are now fake

local gpu, screen = oc.addScreen(117, 35)      -- a 5x3 screen
local plant = oc.gtMachine("multimachine.purificationplant", {work = true, maxProgress = 2400})

t.test("draws the title", function ()
  local ui = require("addons.neon-ui")
  -- ... draw ...
  t.contains(screen.text()[1], "WATER LINE")
  t.snapshot("main", screen.lines())           -- saved as testkit/out/...-main.png
end)

return t.finish()
```

Checks: `t.equal`, `t.truthy`, `t.falsy`, `t.contains`, `t.errors`. Time: `os.sleep(s)` or `oc.advance(s)` runs timers.
Fakes: `oc.gtMachine`, `oc.transposer`, `oc.meInterface`, `oc.meNetwork` (items, fluids, CPUs, power, crafting jobs), `oc.addScreen`, `oc.addComponent` for anything else.

## Copied from OpenComputers on purpose

Listeners outlive the program that made them, `event.pull` names are patterns, listener errors are only logged,
`getTankCount` gives `nil` on a side without a tank, `getFluidInTank` errors on a bad index, an empty tank has no
`name` or `amount`, a screen can leave the GPU. Each of these hid a real bug once.
