# GTNH-OC-Addons

Shared parts for my OpenComputers programs in GTNH 2.9. Each program picks the addons it needs, and they are bundled into its release.

## Addons

<!-- catalog:start -->
| Addon | Version | What it does | Needs |
|---|---|---|---|
| [core](addons/core) | 1.0.0 | Loads addons with their settings from addon.lua, /home/addons.cfg and the program | - |
| [neon-ui](addons/neon-ui) | 1.0.0 | Neon style building blocks: canvas, cards, bars with a slider, rows, header, footer, log | - |
| [screen](addons/screen) | 1.0.0 | Shows frames of coloured lines without flicker, fits the resolution to the screen's shape | - |
<!-- catalog:end -->

Written by `python3 tools/catalog.py` from each `addon.lua`.

## New addon

Copy [`addons/_template`](addons/_template), follow [FORMAT.md](FORMAT.md), run `python3 tools/check_addons.py`.

## License

MIT
