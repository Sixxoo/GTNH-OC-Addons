# installer

Installs, updates and removes programs. Each program lives in its own folder `/home/<id>/` with its own copy of the
addons it was tested with, so programs never get in each other's way. Installed programs are listed in
`/home/.programs`, so `update-all` can update them all at once.

## A program for the installer

`program.lua` in the program's repository and archive:

```lua
return {
  id = "water-line",                         -- folder /home/water-line, file list water-line.files
  name = "Water Line Control",
  version = "2.2.0",
  repository = "Sixxoo/GTNH-OC-Water-Line-Control",
  branch = "main",
  archive = "WaterLineControl.tar",          -- the release asset
  start = "main",                            -- command that starts it, in its folder
  config = "config.lua",                     -- the player's settings, kept on every update
  configRules = {moved = {}, whenMissing = {}},   -- see the config addon
}
```

`setup.lua` in the repository is [bootstrap.lua](bootstrap.lua) with `{{repository}}` and `{{branch}}` filled in.
It downloads the release, unpacks it and calls `finish`.

## Usage

```lua
local installer = require("addons.core").load("installer")
installer.finish(program, oldConfigText)     -- after unpacking: config merge, registry, questions
installer.install(program, "2.2.1")          -- download, unpack, finish
installer.updateAll()                        -- what the update-all command runs
installer.uninstall("water-line")            -- files from water-line.files; config.lua stays
installer.compareVersions("1.2.10", "1.2.9") -- 1
```

What `finish` does:

1. Keeps the player's config: copies it to `config.old.lua` and carries its values into the new file.
2. Registers the program in `/home/.programs`.
3. Asks for shared settings that the program's addons mark with an `ask` question and `/home/addons.cfg` doesn't
   have yet, and saves them there. Next time only new ones are asked.
4. Writes the commands `update-all` and `addons-config` to `/home/bin`.
5. Offers to start the program at boot (instead of another one) and wake on redstone.

## Settings

None.

## Components

`internet` (an internet card).

## Changelog

- 1.1.0 (2026-11-11): `install` shows its steps as it goes (downloading with the size, unpacking, checking, settings), so an update doesn't look stuck. `write(text)` can be replaced like `print`.
- 1.0.0 (2026-11-08): first version, from Water Line Control's setup and updater.
