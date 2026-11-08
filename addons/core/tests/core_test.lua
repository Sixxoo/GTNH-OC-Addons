local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

-- A throwaway addon "demo" in a temporary folder, found like an installed addon
local folder = os.tmpname()
os.remove(folder)
os.execute('mkdir -p "'..folder..'/addons/demo"')

local function write(path, text)
  local file = assert(io.open(path, "w"))
  file:write(text)
  file:close()
end

write(folder.."/addons/demo/addon.lua", [[
return {name = "demo", version = "1.0.0", description = "Test addon",
  settings = {
    interval = {default = 5, description = "Seconds"},
    label = {default = "x", description = "Shown"},
  }}
]])
write(folder.."/addons/demo/init.lua", [[
local M = {calls = 0}
function M.setup(settings) M.settings = settings M.calls = M.calls + 1 end
return M
]])

package.path = folder.."/?.lua;"..folder.."/?/init.lua;"..package.path

local core = require("addons.core")
core.configPath = folder.."/addons.cfg"

t.test("defaults from addon.lua when there is no addons.cfg", function ()
  local settings = core.settings("demo")
  t.equal(settings.interval, 5)
  t.equal(settings.label, "x")
  t.equal(#core.warnings, 0, "warnings")
end)

t.test("addons.cfg overrides defaults, the program overrides addons.cfg", function ()
  write(core.configPath, "return {demo = {interval = 30, label = 'from cfg'}}")
  core.reloadConfig()

  local demo = core.load("demo", {label = "from program"})
  t.equal(demo.settings.interval, 30, "interval from addons.cfg")
  t.equal(demo.settings.label, "from program", "label from the program")
  t.equal(demo.calls, 1, "setup called once")
end)

t.test("an unknown setting in addons.cfg is kept but warned about", function ()
  write(core.configPath, "return {demo = {intervall = 3}}")
  core.reloadConfig()
  core.warnings = {}

  local settings = core.settings("demo")
  t.equal(settings.interval, 5, "real setting keeps its default")
  t.contains(core.warnings[1], "unknown setting demo.intervall")
end)

t.test("a broken addons.cfg is ignored with a warning, defaults are used", function ()
  write(core.configPath, "return {demo = {interval = ")
  core.reloadConfig()
  core.warnings = {}

  local settings = core.settings("demo")
  t.equal(settings.interval, 5)
  t.contains(core.warnings[1], "ignored")
end)

t.test("addons.cfg cannot run code that reaches the computer", function ()
  write(core.configPath, "os.remove('x') return {}")
  core.reloadConfig()
  core.warnings = {}

  core.settings("demo")
  t.contains(core.warnings[1], "ignored")
end)

t.test("load without overrides keeps an addon's settings, with overrides sets it up again", function ()
  write(core.configPath, "return {}")
  core.reloadConfig()
  local demo = core.load("demo", {label = "mine"})
  local calls = demo.calls
  core.load("demo")
  t.equal(demo.settings.label, "mine", "kept")
  t.equal(demo.calls, calls, "setup not called again")
  core.load("demo", {label = "other"})
  t.equal(demo.settings.label, "other")
  core.reload("demo")
  t.equal(demo.settings.label, "x", "reload: back to addons.cfg and defaults")
end)

t.test("loading an addon that does not exist names it", function ()
  t.errors(function () core.load("nope") end, "nope")
end)

os.execute('rm -rf "'..folder..'"')

return t.finish()
