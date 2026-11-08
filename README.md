# GTNH-OC-Addons

Shared parts for OpenComputers programs in GregTech: New Horizons 2.9: the neon screen style, installer,
config, logs, Discord alerts, GT and AE2 helpers. Each program picks the addons it needs, and they are bundled into
its release, so installing a program stays one command.

## How it works

- Every addon is a folder in [`addons/`](addons) with `addon.lua` (name, version, what it needs), `init.lua` (the code)
  and `README.md`. The rules are in [FORMAT.md](FORMAT.md).
- A program lists its addons in `addons.lua`, e.g. `"neon-ui@1"`. Its release workflow copies those addons, everything
  they need and [`core`](addons/core) into the program's archive.
- Settings shared by all programs on one OC computer (time zone, Discord, autostart) live in `/home/addons.cfg`.
- A fix or a new option in an addon (1.x) reaches every program that uses it with the program's next release.
  A breaking change (2.0) waits until the program is updated for it.

## Catalog

| Addon | Version | What it does |
|---|---|---|
| [core](addons/core) | 1.0.0 | Loads addons with their settings from addon.lua, /home/addons.cfg and the program |

## Writing an addon

1. Copy [`addons/_template`](addons/_template) to `addons/<name>/`.
2. Fill in `addon.lua`, write `init.lua` by the rules in [FORMAT.md](FORMAT.md), describe it in `README.md`.
3. Run `python3 tools/check_addons.py` (needs `pip install lupa`). It also runs on every push.

## License

MIT, see [LICENSE](LICENSE).
