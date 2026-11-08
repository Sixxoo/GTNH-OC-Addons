# event-log

A log for the screen and for a file. Screen lines are coloured by level, newest first, and the same message again
folds into the newest line with a count, `(x4)`. The file gets the full date and is renamed to `.old` when it grows,
so it never fills the disk.

## Usage

```lua
local addons = require("addons.core")
local log = addons.load("event-log", {tagColors = {["[QC]"] = "cyan"}})
log.start()                          -- also log what other code pushes: event.push("log_info", "text")

log.info("[QC] Next cycle: T2")
log.warning("T3 is low on Polyaluminium Chloride")
ui.log(cv, x, y, w, h, "EVENT LOG", log.lines(), offset)   -- with neon-ui
log.stop()                           -- when the program ends
```

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `screenLevel` | `"info"` | Lowest level on the screen: `debug`, `info`, `warning`, `error` |
| `screenLines` | `32` | Lines kept for the screen |
| `screenTime` | `"%H:%M"` | Time in front of screen lines |
| `tagColors` | `{}` | Colour of info lines by their start, e.g. `{["[QC]"] = "cyan"}` |
| `filePath` | `"/home/logs.log"` | Log file, `""` for none |
| `fileLevel` | `"info"` | Lowest level written to the file |
| `fileTime` | `"%d.%m.%Y %H:%M:%S"` | Time in front of file lines |
| `fileMaxKb` | `64` | Size at which the file becomes `.old` and a new one starts |

## Components

None. Needs [clock](../clock).

## Changelog

- 1.0.0 (2026-11-08): first version, from Water Line Control; the file now rotates.
