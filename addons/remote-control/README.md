# remote-control

Commands a program offers to other computers: status, stop, switch a unit... Only computers listed in `allowFrom` may run them, nobody by default.

## Usage

```lua
local addons = require("addons.core")
local remote = addons.load("remote-control", {allowFrom = {"3f2a"}})   -- or set it in /home/addons.cfg

remote.command("status", function (args, from) return {plant = "running", t3 = "840k"} end, "Plant and water state")
remote.command("stop", function () lineController:disable() return "stopped" end, "Switch the plant off")
remote.start()

-- on another computer (also with remote-control)
local answer, problem = remote.call(address, "status")
remote.help(address)          -- {status = "Plant and water state", stop = "..."}
```

A refused command is logged with the sender's address, so you can see what to put in `allowFrom`. `{"*"}` allows every
computer in range: only do that on a network nobody else can reach.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `allowFrom` | `{}` | Card addresses (or starts) allowed to send commands; `{"*"}` = every computer |

## Components

`modem`, through `network`.

## Changelog

- 1.0.0 (2026-11-08): first version.
