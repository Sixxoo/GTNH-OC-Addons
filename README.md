# GTNH-OC-Addons

Shared parts for my OpenComputers programs in GTNH 2.9. Each program picks the addons it needs, and they are bundled into its release.

## Addons

<!-- catalog:start -->
| Addon | Version | What it does | Needs |
|---|---|---|---|
| [autostart](addons/autostart) | 1.0.0 | Starts a program when the computer boots, and wakes the computer by redstone after a power loss | - |
| [clock](addons/clock) | 1.0.0 | Real time with a time zone (not game time), cheap to call often | - |
| [config](addons/config) | 1.0.0 | Program settings: a schema, every mistake listed by its path, edit in place, merge on update | - |
| [core](addons/core) | 1.1.0 | Loads addons with their settings from addon.lua, /home/addons.cfg and the program | - |
| [event-log](addons/event-log) | 1.0.0 | Log for the screen (coloured, newest first, repeats folded) and a file that rotates | core@1.1, clock@1 |
| [gt-machine](addons/gt-machine) | 1.0.0 | GregTech machines: find by name, state, switch on and off, sensor values by key | - |
| [installer](addons/installer) | 1.0.0 | Installs, updates and removes programs in /home/<id>/, keeps their config, update-all for all | core@1.1, config@1, autostart@1 |
| [neon-ui](addons/neon-ui) | 1.0.0 | Neon style building blocks: canvas, cards, bars with a slider, rows, header, footer, log | - |
| [recovery](addons/recovery) | 1.0.0 | Restarts a failing program after a pause, cleans up its listeners, safe state after minutes of errors | - |
| [screen](addons/screen) | 1.0.0 | Shows frames of coloured lines without flicker, fits the resolution to the screen's shape | - |
| [transposer](addons/transposer) | 1.0.0 | Finds fluids and items around a transposer and moves them into a hatch on any side | - |
<!-- catalog:end -->

Written by `python3 tools/catalog.py` from each `addon.lua`.

## New addon

Copy [`addons/_template`](addons/_template), follow [FORMAT.md](FORMAT.md), run `python3 tools/check_addons.py`.

## License

MIT
