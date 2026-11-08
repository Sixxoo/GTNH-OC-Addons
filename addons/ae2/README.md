# ae2

The ME network through an adapter on an ME interface (`me_interface`) or controller (`me_controller`).
One way to name what you want, for items and fluids alike, cached craftable lookups, crafting requests
you can follow, power and crafting CPUs. The other ME addons are built on it.

## Usage

```lua
local addons = require("addons.core")
local ae2 = addons.load("ae2")

local me = assert(ae2.find())                          -- settings.address, else the first one
ae2.stock(me, "fluid:water")                           -- 5000000
ae2.stock(me, "gregtech:gt.blockores:86")              -- name:damage
ae2.stock(me, {label = "Iron Ingot"})

local job, problem = ae2.request(me, "minecraft:iron_ingot", 64)
ae2.jobState(job)                                      -- "computing", "running", "done", "failed", "canceled"

ae2.power(me)                                          -- {stored, max, fraction, usage, injection, idle}
ae2.cpus(me)                                           -- {{name, storage, coprocessors, busy, cpu}}
```

| Function | What it does |
|---|---|
| `find(address?)` | The ME interface or controller, or nil and why |
| `spec(what)` / `key(stack)` | Read a key (`"fluid:water"`, `"name"`, `"name:damage"`, or a table), make one from a stack |
| `stock(proxy, what)` | Amount in the network (0 when none) and its label |
| `items(proxy, filter?)` | Items matching a filter, filtered by the network: `{key, name, damage, label, size, craftable}` |
| `fluids(proxy)` | Every fluid: `name -> {name, label, amount}` |
| `craftable(proxy, what)` | The pattern for it, or nil; cached (also "not craftable") |
| `forget()` | Drop the craftable cache (after adding patterns) |
| `request(proxy, what, amount, cpu?)` | Start crafting, returns the job or nil and why |
| `jobState(job)` | State of a job, and why it failed |
| `power(proxy)` / `cpus(proxy)` | Power in AE, crafting CPUs |

GTNH 2.9 keeps items and fluids in one network: fluid stacks have `amount`, item stacks `size` and `damage`.
Reading big networks costs the server time, so ask for what you need (a filter) instead of every item.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `address` | `""` | Address (or its start) of the ME interface or controller; empty takes the first one |
| `craftableCacheSeconds` | `600` | How long a craftable lookup is kept |

## Components

`me_interface` or `me_controller` (an adapter touching one).

## Changelog

- 1.0.0 (2026-11-08): first version.
