# GTNH-OC-Addons

Shared parts for my OpenComputers programs in GTNH 2.9. Each program picks the addons it needs, and they are bundled into its release.

## Addons

<!-- catalog:start -->
| Addon | Version | What it does | Needs |
|---|---|---|---|
| [core](addons/core) | 1.0.0 | Loads addons with their settings from addon.lua, /home/addons.cfg and the program | - |
<!-- catalog:end -->

Written by `python3 tools/catalog.py` from each `addon.lua`.

## New addon

Copy [`addons/_template`](addons/_template), follow [FORMAT.md](FORMAT.md), run `python3 tools/check_addons.py`.

## License

MIT
