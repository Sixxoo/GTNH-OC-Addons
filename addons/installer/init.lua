-- Installs, updates and removes programs. Each program lives in /home/<id>/ with its own addons/,
-- describes itself in program.lua, and is registered in /home/.programs so update-all finds it.
--
-- program.lua of a program:
--   return {id = "water-line", name = "Water Line Control", version = "2.2.0",
--     repository = "Sixxoo/GTNH-OC-Water-Line-Control", branch = "main", archive = "WaterLineControl.tar",
--     start = "main", config = "config.lua", configRules = {moved = {...}, whenMissing = {...}}}
local M = {}

M.home = "/home"
M.registryPath = "/home/.programs"

function M.setup(settings)
  M.settings = settings
end

-- ---------- small helpers (replaceable in tests) ----------

function M.print(line)
  print(line)
end

---Yes/no question; Enter alone is the default
function M.ask(question, default)
  io.write(question..(default and " [Y/n] " or " [y/N] "))
  local answer = io.read()

  if answer == nil or answer == "" then
    return default == true
  end

  return answer:lower():sub(1, 1) == "y"
end

---Question with a text answer; Enter alone keeps the default
function M.askText(question, default)
  io.write(question.." ["..tostring(default).."]: ")
  local answer = io.read()

  if answer == nil or answer == "" then
    return default
  end

  if type(default) == "number" then
    return tonumber(answer) or default
  end

  if type(default) == "boolean" then
    return answer:lower():sub(1, 1) == "y" or answer == "true"
  end

  return answer
end

---Text of a URL, or nil and why
function M.fetch(url)
  local isOk, result = pcall(function ()
    local request = require("internet").request(url)
    local parts = {}

    for chunk in request do
      parts[#parts + 1] = chunk
    end

    return table.concat(parts)
  end)

  if not isOk then
    return nil, tostring(result)
  end

  return result
end

---Download a file. Not to /tmp: it is a 64 KB RAM disk, too small for a release
function M.download(url, path)
  local filesystem = require("filesystem")
  filesystem.remove(path)
  require("shell").execute("wget -fq "..url.." "..path)
  return filesystem.exists(path) and filesystem.size(path) > 0
end

---Unpack a tar archive into a folder
function M.extract(archive, folder)
  local shell = require("shell")
  local before = shell.getWorkingDirectory()
  shell.setWorkingDirectory(folder)
  shell.execute("tar -xf "..archive)
  shell.setWorkingDirectory(before)
end

local function read(path)
  local file = io.open(path, "r")

  if file == nil then
    return nil
  end

  local text = file:read("*a")
  file:close()
  return text
end

local function write(path, text)
  local file = io.open(path, "w")

  if file == nil then
    error("[installer] can't write "..path)
  end

  file:write(text)
  file:close()
end

---A Lua file that returns a table, read without access to anything
local function readTable(text, name)
  if text == nil then
    return nil, "missing"
  end

  local chunk, problem = load(text, "="..name, "t", {})

  if chunk == nil then
    return nil, problem
  end

  local isOk, value = pcall(chunk)

  if not isOk or type(value) ~= "table" then
    return nil, isOk and "not a table" or tostring(value)
  end

  return value
end

---Write a value as Lua: strings, numbers, booleans and tables of them
function M.serialize(value, indent)
  indent = indent or ""
  local kind = type(value)

  if kind == "string" then
    return (string.format("%q", value):gsub("\\\n", "\\n"))
  elseif kind == "number" or kind == "boolean" then
    return tostring(value)
  elseif kind ~= "table" then
    return "nil"
  end

  local keys = {}

  for key in pairs(value) do
    keys[#keys + 1] = key
  end

  table.sort(keys, function (a, b) return tostring(a) < tostring(b) end)

  if #keys == 0 then
    return "{}"
  end

  local lines = {"{"}

  for _, key in ipairs(keys) do
    local name = type(key) == "string" and key:match("^[%a_][%w_]*$") and key or ("["..M.serialize(key).."]")
    lines[#lines + 1] = indent.."  "..name.." = "..M.serialize(value[key], indent.."  ")..","
  end

  lines[#lines + 1] = indent.."}"
  return table.concat(lines, "\n")
end

---Compare versions "1.2.10": -1, 0 or 1
function M.compareVersions(a, b)
  local aParts, bParts = tostring(a):gmatch("%d+"), tostring(b):gmatch("%d+")

  while true do
    local x, y = aParts(), bParts()

    if x == nil and y == nil then
      return 0
    end

    x, y = tonumber(x) or 0, tonumber(y) or 0

    if x ~= y then
      return x < y and -1 or 1
    end
  end
end

-- ---------- registry ----------

---Installed programs: id -> program.lua table + folder
function M.registry()
  return readTable(read(M.registryPath), ".programs") or {}
end

local function saveRegistry(registry)
  write(M.registryPath, "return "..M.serialize(registry).."\n")
end

-- ---------- installing ----------

---program.lua of the newest version on GitHub, or nil and why
function M.latest(program)
  local url = "https://raw.githubusercontent.com/"..program.repository.."/refs/heads/"..(program.branch or "main").."/program.lua"
  local text, problem = M.fetch(url)

  if text == nil then
    return nil, problem
  end

  return readTable(text, "program.lua")
end

---Ask for shared settings the program's addons need and /home/addons.cfg doesn't have yet.
---Only settings with an `ask` question in their addon.lua are asked; the rest keep their defaults
local function askSharedSettings(folder, lines)
  local filesystem = require("filesystem")
  local core = require("addons.core")
  local path = core.configPath
  local shared = readTable(read(path), "addons.cfg") or {}
  local changed = false

  for name in (filesystem.list and filesystem.list(folder.."/addons") or function () return nil end) do
    name = tostring(name):gsub("/$", "")
    local info = readTable(read(folder.."/addons/"..name.."/addon.lua"), "addon.lua")

    for key, setting in pairs(info and info.settings or {}) do
      if setting.ask ~= nil and (shared[name] == nil or shared[name][key] == nil) then
        shared[name] = shared[name] or {}
        shared[name][key] = M.askText(setting.ask, setting.default)
        changed = true
      end
    end
  end

  if changed then
    write(path, "-- Settings shared by every program on this computer. Change them with: addons-config\nreturn "..M.serialize(shared).."\n")
    core.reloadConfig()
    lines[#lines + 1] = "Shared settings saved to "..path.."."
  end
end

---Commands every program gets: update-all and addons-config in /home/bin
local function writeCommands(folder)
  local filesystem = require("filesystem")
  filesystem.makeDirectory(M.home.."/bin")
  write(M.home.."/bin/update-all.lua", 'package.path = "'..folder..'/?.lua;'..folder..'/?/init.lua;" .. package.path\n'
    ..'require("addons.installer").updateAll()\n')
  write(M.home.."/bin/addons-config.lua", 'require("shell").execute("edit '..require("addons.core").configPath..'")\n')
end

---config.old.lua, or config.old2.lua, ... if that is taken
local function backupName(folder)
  local filesystem = require("filesystem")
  local name, number = "config.old.lua", 1

  while filesystem.exists(folder.."/"..name) do
    number = number + 1
    name = "config.old"..number..".lua"
  end

  return name
end

---Everything after the files are unpacked: config, registry, shared settings, autostart, wake.
---setup.lua (bootstrap) calls this after it unpacked a program; install() calls it after an update
---@param program table program.lua of the unpacked version
---@param oldConfig? string The player's config file before the files were replaced
---@return string[] lines What happened
function M.finish(program, oldConfig)
  local folder = M.home.."/"..program.id
  local lines = {}
  local configName = program.config or "config.lua"

  -- Config: the player's values in the new file's layout
  if oldConfig ~= nil then
    local backup = backupName(folder)
    write(folder.."/"..backup, oldConfig)
    local newText = read(folder.."/"..configName) or ""
    local merged, report = require("addons.config").merge(oldConfig, newText, program.configRules)

    if merged ~= nil then
      write(folder.."/"..configName, merged)
      lines[#lines + 1] = "Your settings are in the new "..configName.." (the old file is "..backup.."):"

      for _, line in ipairs(require("addons.config").describe(report)) do
        lines[#lines + 1] = "  "..line
      end
    else
      write(folder.."/config.default.lua", newText)
      write(folder.."/"..configName, oldConfig)
      lines[#lines + 1] = "Kept your "..configName.." as it was: "..tostring(report)
      lines[#lines + 1] = "The new one is config.default.lua."
    end
  end

  -- Registry, so update-all finds it
  local registry = M.registry()
  local entry = {}

  for key, value in pairs(program) do
    if type(value) ~= "table" then
      entry[key] = value
    end
  end

  entry.folder = folder
  registry[program.id] = entry
  saveRegistry(registry)

  askSharedSettings(folder, lines)
  writeCommands(folder)

  -- Start at boot and wake on redstone
  local autostart = require("addons.core").load("autostart")
  local currentFolder = autostart.current()

  if currentFolder == folder then
    lines[#lines + 1] = program.name.." starts at boot."
  else
    local other = nil

    for _, each in pairs(registry) do
      if each.folder == currentFolder then other = each.name end
    end

    local question = "Start "..program.name.." when the computer boots?"

    if currentFolder ~= nil then
      question = "Start "..program.name.." at boot instead of "..(other or currentFolder).."?"
    end

    if M.ask(question, currentFolder == nil) then
      autostart.enable(folder, program.start or "main")
      lines[#lines + 1] = program.name.." starts at boot."
    end
  end

  local wake = autostart.wakeIsOn()

  if wake == false and M.ask("Turn the computer on by redstone after a power loss?", false) then
    autostart.enableWake()
    lines[#lines + 1] = "Wake on redstone on: wire a slow redstone clock (a pulse every 30 to 60 s) to the computer."
  end

  return lines
end

---Download and install a version of a program (a new install or an update)
---@param program table program.lua, at least id, name, repository, archive
---@param version string
---@return boolean ok
---@return string[] lines
function M.install(program, version)
  local filesystem = require("filesystem")
  local folder = M.home.."/"..program.id
  local archive = M.home.."/"..program.id.."-update.tar"
  local url = "https://github.com/"..program.repository.."/releases/download/v"..version.."/"..program.archive

  filesystem.makeDirectory(folder)

  if not M.download(url, archive) then
    filesystem.remove(archive)
    return false, {"Could not download "..url}
  end

  local oldConfig = read(folder.."/"..(program.config or "config.lua"))
  M.extract(archive, folder)
  filesystem.remove(archive)

  -- A download that stopped early unpacks only part of the files
  local installed = readTable(read(folder.."/program.lua"), "program.lua")

  if installed == nil or installed.version ~= version then
    return false, {"The download was incomplete, so some files are missing or cut off. Run it again."}
  end

  return true, M.finish(installed, oldConfig)
end

---Check every installed program for a new version, ask once, update them
function M.updateAll()
  local updates = {}

  for id, program in pairs(M.registry()) do
    local latest, problem = M.latest(program)

    if latest == nil then
      M.print(program.name..": can't check ("..tostring(problem)..")")
    elseif M.compareVersions(latest.version, program.version) > 0 then
      M.print(program.name..": "..program.version.." -> "..latest.version)
      updates[#updates + 1] = {program = program, version = latest.version}
    else
      M.print(program.name..": "..program.version.." is the newest")
    end
  end

  if #updates == 0 then
    M.print("Everything is up to date.")
    return 0
  end

  if not M.ask("Update "..#updates.." program(s)?", false) then
    return 0
  end

  local done = 0

  for _, update in ipairs(updates) do
    local isOk, lines = M.install(update.program, update.version)

    for _, line in ipairs(lines) do
      M.print(line)
    end

    if isOk then
      done = done + 1
    end
  end

  return done
end

---Remove a program: its files (listed in <id>.files), its registry entry and its autostart line.
---The player's config file stays unless removeConfig
function M.uninstall(id, removeConfig)
  local filesystem = require("filesystem")
  local registry = M.registry()
  local program = registry[id]

  if program == nil then
    return false, {id.." is not installed"}
  end

  local folder = program.folder
  local list = read(folder.."/"..id..".files")

  if list == nil then
    return false, {"There is no "..id..".files, the list of installed files. Nothing was removed."}
  end

  local configName = program.config or "config.lua"
  local removed = 0

  for file in list:gmatch("[^\r\n]+") do
    if file ~= configName or removeConfig then
      local path = folder.."/"..file

      if filesystem.exists(path) and not filesystem.isDirectory(path) then
        filesystem.remove(path)
        removed = removed + 1
      end
    end
  end

  registry[id] = nil
  saveRegistry(registry)

  local autostart = require("addons.core").load("autostart")

  if autostart.current() == folder then
    autostart.disable()
  end

  return true, {"Removed "..removed.." files of "..program.name.."."}
end

return M
