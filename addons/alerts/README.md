# alerts

Problems that need you, in one list until they are fixed. Each alert is logged once (and again only when its text or level changes), the screen can show the count and the worst level, and a redstone output can light a lamp or sound a siren while alerts are active. Other addons raise alerts with signals, so they don't depend on this one.

## Usage

```lua
local addons = require("addons.core")
local alerts = addons.load("alerts")

alerts.start()                                     -- takes alert_raise / alert_clear signals
alerts.raise("t3", "warning", "T3 needs attention")
alerts.raise("power", "critical", "Computer energy 5%")
alerts.clear("t3")                                 -- logs "Fixed: T3 needs attention"

alerts.count()      -- 1
alerts.worst()      -- "critical"
alerts.list()       -- {{key, level, text, since}}, critical first
alerts.stop()       -- also switches the redstone off

-- from anywhere, without loading the addon:
event.push("alert_raise", "me", "warning", "Disks 95% full")
event.push("alert_clear", "me")
```

Pushes `alert_changed` (key, level or nil, text) on every change. `power` raises its alerts this way.

## Settings

| Setting | Default | What it changes |
|---|---|---|
| `redstoneSide` | `""` | Side of a redstone card or Redstone I/O that is on while an alert is active (`""` = none), e.g. `"top"` |
| `redstoneLevel` | `"warning"` | Lowest level that turns it on: `"warning"` or `"critical"` |

## Components

`redstone` (optional, for a lamp or siren).

## Changelog

- 1.0.0 (2026-11-08): first version.
