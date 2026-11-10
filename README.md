# GTNH-OC-Addons

Shared parts for my OpenComputers programs in GTNH 2.9. Each program picks the addons it needs, and they are bundled into its release.

## Addons

<!-- catalog:start -->
### Base

Loading, installing, settings, starting, staying up.

| Addon | Version | What it does | Needs |
|---|---|---|---|
| [core](addons/core) | 1.1.0 | Loads addons with their settings from addon.lua, /home/addons.cfg and the program | - |
| [installer](addons/installer) | 1.0.0 | Installs, updates and removes programs in /home/<id>/, keeps their config, update-all for all | core 1.1.0, config 1.0.0, autostart 1.0.0 |
| [config](addons/config) | 1.0.0 | Program settings: a schema, every mistake listed by its path, edit in place, merge on update | - |
| [autostart](addons/autostart) | 1.0.0 | Starts a program when the computer boots, and wakes the computer by redstone after a power loss | - |
| [recovery](addons/recovery) | 1.3.0 | Restarts a failing program after a pause, cleans up its listeners, safe state after minutes of errors | - |

### Monitor Screen

The neon look, drawing it, pages, touch, charts, time and the event log on the screen.

| Addon | Version | What it does | Needs |
|---|---|---|---|
| [neon-ui](addons/neon-ui) | 1.0.0 | Neon style building blocks: canvas, cards, bars with a slider, rows, header, footer, log | - |
| [screen](addons/screen) | 1.0.0 | Shows frames of coloured lines without flicker, fits the resolution to the screen's shape | - |
| [tabs](addons/tabs) | 1.0.0 | Pages on one screen: a neon tab row, switched with Tab, arrows, number keys or a touch | neon-ui 1.0.0 |
| [touch](addons/touch) | 1.0.0 | Buttons and touch areas on the screen: draw a neon button, know which one was touched | neon-ui 1.0.0 |
| [widgets](addons/widgets) | 1.0.0 | Ready-made neon pieces: value tiles, status lights, a table with columns, a meter | neon-ui 1.0.0 |
| [charts](addons/charts) | 1.0.0 | Charts on a neon-ui canvas: columns with labels, a one-row sparkline, horizontal bars | neon-ui 1.0.0 |
| [big-font](addons/big-font) | 1.0.0 | Big text five rows high for numbers and short words you read from across the room | neon-ui 1.0.0 |
| [windows](addons/windows) | 1.0.0 | Pop-up windows over the screen: messages and questions with buttons, by key or touch | neon-ui 1.0.0 |
| [multi-screen](addons/multi-screen) | 1.0.0 | Several screens from one computer: each screen its own frame, one GPU per screen or one shared GPU | - |
| [ar-glasses](addons/ar-glasses) | 1.0.0 | Text and bars on the HUD of AR glasses (OpenGlasses glasses terminal), kept up to date by key | - |
| [clock](addons/clock) | 1.1.0 | Real time with a time zone (not game time), cheap to call often | - |
| [event-log](addons/event-log) | 1.0.0 | Log for the screen (coloured, newest first, repeats folded) and a file that rotates | core 1.1.0, clock 1.1.0 |

### Machines

GregTech machines and transposers.

| Addon | Version | What it does | Needs |
|---|---|---|---|
| [gt-machine](addons/gt-machine) | 1.0.0 | GregTech machines: find by name, state, switch on and off, sensor values by key | - |
| [transposer](addons/transposer) | 1.0.0 | Finds fluids and items around a transposer and moves them into a hatch on any side | - |

### Safety

Alerts, power and checks that catch problems early.

| Addon | Version | What it does | Needs |
|---|---|---|---|
| [alerts](addons/alerts) | 1.0.0 | Problems that need you, in one list until fixed: logged once, a count for the screen, a redstone lamp or siren | - |
| [power](addons/power) | 1.0.0 | The computer's own power: warns before it runs out, and tells after a restart when and how it went off | clock 1.1.0 |
| [wiring-check](addons/wiring-check) | 1.0.0 | Checks at start that every component in the config is there; for a missing one names unused ones of its type | - |

### ME System features

Stock, crafting and storage of the ME network.

| Addon | Version | What it does | Needs |
|---|---|---|---|
| [ae2](addons/ae2) | 1.0.0 | ME network: find it, read items and fluids by one key, power, CPUs, cached craftables, requests | - |
| [stock-watch](addons/stock-watch) | 1.0.0 | Watches items and fluids in the ME network against a minimum and maximum, logs when one runs low | ae2 1.0.0 |
| [cpu-monitor](addons/cpu-monitor) | 1.0.0 | Crafting CPUs of the ME network: busy or free, what each crafts and for how long, logs jobs | ae2 1.0.0 |
| [craft-history](addons/craft-history) | 1.0.0 | Keeps finished crafting jobs (from cpu-monitor) in a file: recent jobs and totals per item | cpu-monitor 1.0.0, clock 1.1.0 |
| [me-capacity](addons/me-capacity) | 1.0.0 | Free space on the storage cells in ME Drives (bytes and types), read by transposers next to the drives | - |
| [ore-yield](addons/ore-yield) | 1.0.0 | How fast items come into the ME network per hour, e.g. ores from miners, void miners or a meteor | ae2 1.0.0, clock 1.1.0 |

### Data

Statistics and history that survive restarts.

| Addon | Version | What it does | Needs |
|---|---|---|---|
| [stats](addons/stats) | 1.0.0 | Counters and readings kept per hour in a file: totals, per hour, last 24 hours, min/max/average, uptime | clock 1.1.0 |
| [history](addons/history) | 1.0.0 | Long history of values in a file at several resolutions: minutes for hours, quarters for days, hours for a month | clock 1.1.0 |

### OC Network

Computers talking to each other.

| Addon | Version | What it does | Needs |
|---|---|---|---|
| [network](addons/network) | 1.0.0 | Messages between OC computers over a network card: send, broadcast, ask and get an answer | - |
| [central-server](addons/central-server) | 1.0.0 | One computer sees all others: each program reports its status, the server lists them and notices when one goes quiet | network 1.0.0 |
| [remote-control](addons/remote-control) | 1.0.0 | Commands a program offers to other computers (status, stop, switch...), only for allowed computers | network 1.0.0 |

### Development

Help while building and tuning a program.

| Addon | Version | What it does | Needs |
|---|---|---|---|
| [debug](addons/debug) | 1.0.0 | Help while building a program: readable dumps, components, memory, signals as they come, errors with a traceback | - |
| [profiler](addons/profiler) | 1.0.0 | Where a program spends its time and component calls: measure functions, count calls on a component | - |
<!-- catalog:end -->

Written by `python3 tools/catalog.py` from each `addon.lua` and [groups.lua](groups.lua).

## New addon

Copy [`addons/_template`](addons/_template), follow [FORMAT.md](FORMAT.md), add it to a group in [groups.lua](groups.lua), run `python3 tools/check_addons.py`.

## License

MIT
