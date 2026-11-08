local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local home = os.tmpname()
os.remove(home)
os.execute('mkdir -p "'..home..'"')

local function write(path, text)
  os.execute('mkdir -p "'..path:match("^(.*)/[^/]*$")..'"')
  local file = assert(io.open(path, "w")) file:write(text) file:close()
end

local function read(path)
  local file = io.open(path, "r") if file == nil then return nil end
  local text = file:read("*a") file:close() return text
end

local addons = require("addons.core")
addons.configPath = home.."/addons.cfg"
addons.load("autostart", {shrc = home.."/.shrc"})
local installer = addons.load("installer")
installer.home = home
installer.registryPath = home.."/.programs"

local printed = {}
installer.print = function (line) printed[#printed + 1] = line end
local answers = {}
installer.ask = function (question) return answers[question] == true end
installer.askText = function (_, default) return answers.text or default end

local program = {id = "demo", name = "Demo", version = "1.1.0", repository = "Sixxoo/Demo", branch = "main",
  archive = "Demo.tar", start = "main", config = "config.lua"}

-- An unpacked new version: program.lua, the new config.lua, an addon with a question
local folder = home.."/demo"
write(folder.."/program.lua", "return "..installer.serialize(program))
write(folder.."/config.lua", "local config = {\n  limit = 32, -- Litres\n  floor = 5,\n}\nreturn config\n")
write(folder.."/addons/clock/addon.lua", [[return {name = "clock", version = "1.0.0", description = "x",
  settings = {timeZone = {default = 0, description = "Hours", ask = "Time zone, hours from UTC"}}}]])

t.test("versions compare by number, not text", function ()
  t.equal(installer.compareVersions("1.2.10", "1.2.9"), 1)
  t.equal(installer.compareVersions("2.1.0", "2.1"), 0)
  t.equal(installer.compareVersions("1.9.0", "2.0.0"), -1)
end)

t.test("finish keeps the player's config values, with a backup", function ()
  answers = {text = 1}
  local lines = installer.finish(program, "local config = {\n  limit = 99,\n}\nreturn config\n")
  t.contains(read(folder.."/config.lua"), "limit = 99, -- Litres")
  t.contains(read(folder.."/config.lua"), "floor = 5,")
  t.equal(read(folder.."/config.old.lua"), "local config = {\n  limit = 99,\n}\nreturn config\n")
  t.contains(table.concat(lines, "\n"), "Kept 1 of your settings")
end)

t.test("finish registers the program for update-all", function ()
  local registry = installer.registry()
  t.equal(registry.demo.version, "1.1.0")
  t.equal(registry.demo.folder, folder)
end)

t.test("shared settings with a question are asked once and saved", function ()
  t.contains(read(home.."/addons.cfg"), "timeZone = 1")
  answers = {text = 5}
  installer.finish(program, nil)
  t.contains(read(home.."/addons.cfg"), "timeZone = 1", "not asked again")
end)

t.test("update-all and addons-config commands are written", function ()
  t.contains(read(home.."/bin/update-all.lua"), 'require("addons.installer").updateAll()')
  t.contains(read(home.."/bin/addons-config.lua"), "addons.cfg")
end)

t.test("autostart only when the player says yes, and replaces another program", function ()
  answers = {["Start Demo when the computer boots?"] = true}
  installer.finish(program, nil)
  t.contains(read(home.."/.shrc"), "cd "..folder.." && main # autostart")

  local other = {id = "other", name = "Other", version = "1.0.0", repository = "x/y", archive = "O.tar", start = "run"}
  write(home.."/other/program.lua", "return {}")
  answers = {["Start Other at boot instead of Demo?"] = true}
  installer.finish(other, nil)
  t.contains(read(home.."/.shrc"), "cd "..home.."/other && run # autostart")
  t.falsy(read(home.."/.shrc"):find(folder.." &&", 1, true), "only one program starts")
end)

t.test("install downloads, unpacks and finishes; an incomplete download is reported", function ()
  local source = os.tmpname() os.remove(source)
  write(source.."/program.lua", 'return {id = "demo", name = "Demo", version = "1.2.0", repository = "Sixxoo/Demo", archive = "Demo.tar", config = "config.lua"}')
  write(source.."/config.lua", "local config = {\n  limit = 64,\n}\nreturn config\n")
  os.execute('cd "'..source..'" && tar -cf "'..source..'.tar" program.lua config.lua')

  local urls = {}
  installer.download = function (url, path)
    urls[#urls + 1] = url
    os.execute('cp "'..source..'.tar" "'..path..'"')
    return true
  end
  installer.extract = function (archive, target) os.execute('cd "'..target..'" && tar -xf "'..archive..'"') end

  local isOk, lines = installer.install(program, "1.2.0")
  t.truthy(isOk, table.concat(lines, "\n"))
  t.contains(urls[1], "/releases/download/v1.2.0/Demo.tar")
  t.contains(read(folder.."/config.lua"), "limit = 99,", "player's value kept")
  t.equal(installer.registry().demo.version, "1.2.0")

  isOk = installer.install(program, "9.9.9")
  t.falsy(isOk, "version in program.lua doesn't match")
  os.execute('rm -rf "'..source..'" "'..source..'.tar"')
end)

t.test("update-all lists what is new and updates after one yes", function ()
  installer.fetch = function (url)
    if url:find("Sixxoo/Demo", 1, true) then return 'return {version = "1.3.0"}' end
    return 'return {version = "1.0.0"}'
  end
  local installed = {}
  installer.install = function (p, version) installed[#installed + 1] = p.id..version return true, {} end

  printed = {}
  answers = {["Update 1 program(s)?"] = true}
  t.equal(installer.updateAll(), 1)
  t.equal(installed[1], "demo1.3.0")
  t.contains(table.concat(printed, "\n"), "Demo: 1.2.0 -> 1.3.0")
  t.contains(table.concat(printed, "\n"), "Other: 1.0.0 is the newest")
end)

t.test("uninstall removes the listed files, keeps config.lua, unregisters", function ()
  write(folder.."/demo.files", "program.lua\nconfig.lua\nmain.lua\n")
  write(folder.."/main.lua", "")
  local isOk = installer.uninstall("demo")
  t.truthy(isOk)
  t.equal(read(folder.."/main.lua"), nil, "main.lua removed")
  t.truthy(read(folder.."/config.lua") ~= nil, "config.lua kept")
  t.equal(installer.registry().demo, nil, "unregistered")
end)

os.execute('rm -rf "'..home..'"')
return t.finish()
