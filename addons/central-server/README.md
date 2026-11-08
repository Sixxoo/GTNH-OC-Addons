# central-server

One computer sees all the others. Every program runs a client that reports its status now and then (name, program, a status word, a few values, its alerts); one computer runs the server, keeps the last report of each and notices when one goes quiet.

## Usage

```lua
local addons = require("addons.core")
local central = addons.load("central-server")

-- in every program
central.startClient({program = "water-line", status = "running"})
central.report({values = {cycles = 120, t3 = "840k"}, alerts = {"T3 needs attention"}})
central.stopClient()                 -- reports "stopped" once

-- on the server computer
central.startServer()
for _, pc in ipairs(central.computers()) do
  -- {address, name, online, ago, program, status, values, alerts, uptime}
end
```

A computer not heard from for `offlineSeconds` is logged as offline and raises an alert (`alerts` addon); it clears when
it reports again. `forget(address)` drops a computer for good.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `name` | `""` | Name to report under; empty = the computer's label, else its address |
| `reportSeconds` | `30` | How often a client reports |
| `offlineSeconds` | `120` | Quiet this long = offline |

## Components

`modem`, through `network`.

## Changelog

- 1.0.0 (2026-11-08): first version.
