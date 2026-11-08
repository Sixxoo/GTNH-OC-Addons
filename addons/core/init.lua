-- Loads addons with their settings: defaults from addon.lua, then the shared /home/addons.cfg,
-- then what the program passes
local M = {}

M.configPath = "/home/addons.cfg"
M.warnings = {}

local sharedConfig = nil
local infos = {}

---Read a Lua file that returns a table, without giving it access to anything
---@param path string
---@return table|nil value
---@return string|nil problem
local function readTable(path)
  local file = io.open(path, "r")

  if file == nil then
    return nil, "missing"
  end

  local text = file:read("*a")
  file:close()

  local chunk, problem = load(text, "="..(path:match("[^/]+$") or path), "t", {})

  if chunk == nil then
    return nil, problem
  end

  local isOk, value = pcall(chunk)

  if not isOk then
    return nil, tostring(value)
  end

  if type(value) ~= "table" then
    return nil, "does not return a table"
  end

  return value
end

---Folder of an addon, found like require finds its init.lua
---@param name string
---@return string
local function addonFolder(name)
  if package.searchpath ~= nil then
    local path = package.searchpath("addons."..name, package.path)

    if path ~= nil then
      return (path:gsub("init%.lua$", ""))
    end
  end

  return "/home/addons/"..name.."/"
end

---The shared settings of this computer, read once. A broken file counts as empty, with a warning
---@return table
function M.sharedConfig()
  if sharedConfig == nil then
    local value, problem = readTable(M.configPath)

    if value == nil then
      if problem ~= "missing" then
        table.insert(M.warnings, "[core] "..M.configPath.." ignored: "..problem)
      end

      value = {}
    end

    sharedConfig = value
  end

  return sharedConfig
end

---Forget the shared settings, so the next load reads the file again (after editing it)
function M.reloadConfig()
  sharedConfig = nil
end

---What addon.lua says about an addon
---@param name string
---@return table
function M.info(name)
  if infos[name] == nil then
    local value, problem = readTable(addonFolder(name).."addon.lua")

    if value == nil then
      error("[core] can't read addon.lua of "..name..": "..tostring(problem))
    end

    infos[name] = value
  end

  return infos[name]
end

---Settings of an addon: defaults, then the shared config, then the program's overrides
---@param name string
---@param overrides? table
---@return table
function M.settings(name, overrides)
  local settings = {}
  local known = M.info(name).settings or {}

  for key, setting in pairs(known) do
    settings[key] = setting.default
  end

  local shared = M.sharedConfig()[name]

  if type(shared) == "table" then
    for key, value in pairs(shared) do
      if known[key] == nil then
        table.insert(M.warnings, "[core] unknown setting "..name.."."..tostring(key).." in "..M.configPath)
      end

      settings[key] = value
    end
  end

  for key, value in pairs(overrides or {}) do
    settings[key] = value
  end

  return settings
end

local setUp = {}

---Load an addon and give it its settings. An addon that is already loaded comes back as it is,
---unless overrides are given: then it is set up again with them
---@param name string
---@param overrides? table Settings the program sets itself
---@return table module
function M.load(name, overrides)
  local module = require("addons."..name)

  if type(module) ~= "table" then
    error("[core] addon "..name.." did not return a table")
  end

  if setUp[name] == module and overrides == nil then
    return module
  end

  if type(module.setup) == "function" then
    module.setup(M.settings(name, overrides))
  end

  setUp[name] = module
  return module
end

---Set an addon up again with the settings from addons.cfg, after it was edited
---@param name string
function M.reload(name)
  setUp[name] = nil
  return M.load(name)
end

return M
