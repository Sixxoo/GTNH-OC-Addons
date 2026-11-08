local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local shrc = os.tmpname()
local autostart = addons.load("autostart", {shrc = shrc})

local function read()
  local file = io.open(shrc, "r") local text = file:read("*a") file:close() return text
end

local function write(text)
  local file = io.open(shrc, "w") file:write(text) file:close()
end

t.test("enable adds one marked line and keeps the player's lines", function ()
  write("alias ll=ls\n")
  autostart.enable("/home/water-line", "main")
  t.equal(read(), "alias ll=ls\ncd /home/water-line && main # autostart\n")
  local folder, command = autostart.current()
  t.equal(folder, "/home/water-line") t.equal(command, "main")
end)

t.test("another program replaces the first, never two", function ()
  autostart.enable("/home/meteor", "main")
  t.equal(read(), "alias ll=ls\ncd /home/meteor && main # autostart\n")
end)

t.test("disable removes only its line", function ()
  autostart.disable()
  t.equal(read(), "alias ll=ls\n")
  t.equal(autostart.current(), nil)
end)

t.test("wake on redstone with a redstone card", function ()
  local threshold = 0
  local address = oc.addComponent("redstone", {
    getWakeThreshold = function () return threshold end,
    setWakeThreshold = function (value) threshold = value end,
  })
  require("component").slot = function (a) return a == address and 3 or -1 end

  t.equal(autostart.wakeIsOn(), false)
  t.truthy(autostart.enableWake())
  t.equal(threshold, 1)
  t.equal(autostart.wakeIsOn(), true)
end)

t.test("a Redstone I/O block (no slot) is not a redstone card", function ()
  require("component").slot = function () return -1 end
  t.equal(autostart.wakeIsOn(), nil)
  t.equal(autostart.enableWake(), false)
end)

os.remove(shrc)
return t.finish()
