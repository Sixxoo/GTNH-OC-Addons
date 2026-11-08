# network

Messages between OpenComputers over a network card (wired or wireless) or a linked card. A message has a kind and data (numbers, strings, booleans and tables of them); a handler's return value goes back as the answer when the sender used `request()`. Data is read back without running any code.

## Usage

```lua
local addons = require("addons.core")
local network = addons.load("network")

network.open()
network.on("ping", function (data, from, distance) return {pong = data.n + 1} end)

network.broadcast("hello", {program = "water-line"})
network.send(address, "hello", {text = "hi"})
local answer, from = network.request(address, "ping", {n = 41})   -- {pong = 42}, or nil, "timeout"

network.address()      -- this computer's card address
network.close()
```

All programs using this addon share one port. A wireless card only reaches computers within its range.
`central-server` and `remote-control` are built on it.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `port` | `4711` | Port all programs using this addon talk on |
| `timeoutSeconds` | `5` | How long `request()` waits |

## Components

`modem` (network card) or `tunnel` (linked card).

## Changelog

- 1.0.0 (2026-11-08): first version.
