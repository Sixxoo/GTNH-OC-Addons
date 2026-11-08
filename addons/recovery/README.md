# recovery

Keeps a program running through errors. A run that fails is stopped and cleaned up (its listeners and timers
cancelled), then started again after 30 s. If it keeps failing for 5 minutes, the program puts its machines in a safe
state and stops. Errors inside listeners and timers stop the run too: OpenOS would only write them to
`/tmp/event.log`.

## Usage

```lua
local addons = require("addons.core")
local recovery = addons.load("recovery")

local result, problem = recovery.run({
  start = function ()
    recovery.listen("key_down", onKey)          -- cancelled when the run ends
    recovery.timer(1, drawScreen, math.huge)
    plant = assert(gt.find("purificationplant"))
  end,
  step = function ()
    controlMachines()
    os.sleep(1)
    return not quitPressed                       -- false ends the program
  end,
  stop = function (reason) end,                  -- every run's end: "quit" or the error
  safe = function (problem) gt.allow(plant, false) end,
  waiting = function (problem, left, attempt, giveUpIn)
    showError(problem, left, attempt, giveUpIn)  -- every second before the restart
    if quitPressed then return "quit" end
  end,
})
```

| Function | What it does |
|---|---|
| `run(handlers)` | Runs until `step` returns false (`"quit"`) or it gives up (`"gave up"`, problem) |
| `listen(name, fn)`, `timer(s, fn, times)` | Like OpenOS, but guarded and cancelled when the run ends |
| `guard(fn)` | A callback whose errors stop the run; does nothing once its run is over |
| `fail(message)` | Report an error of the current run from anywhere |
| `current()` | Number of the current run |

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `retrySeconds` | `30` | Pause before starting again |
| `giveUpMinutes` | `5` | Minutes of failing in a row before the safe state |
| `healthySeconds` | `60` | A run this long counts as working; the next error starts a fresh count |

## Components

None.

## Changelog

- 1.0.0 (2026-11-08): first version, from Water Line Control's program controller.
