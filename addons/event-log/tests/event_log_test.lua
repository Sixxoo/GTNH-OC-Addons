local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local folder = os.tmpname()
os.remove(folder)
os.execute('mkdir -p "'..folder..'"')
addons.load("clock", {tmpFile = folder.."/clock.tmp"})
local logPath = folder.."/logs.log"
local log = addons.load("event-log", {filePath = logPath, screenLines = 3, fileMaxKb = 1,
  tagColors = {["[QC]"] = "cyan"}})

local function readFile(path)
  local file = io.open(path, "r")
  if file == nil then return "" end
  local text = file:read("*a")
  file:close()
  return text
end

t.test("newest first, coloured by level and tag", function ()
  log.clear()
  log.info("Started")
  log.info("[QC] Next cycle: T2")
  log.warning("Low")
  local lines = log.lines()
  t.contains(lines[1], "&yellow;Low")
  t.contains(lines[2], "&cyan;[QC] Next cycle: T2")
  t.contains(lines[3], "&white;Started")
end)

t.test("debug stays off the screen at level info, errors get a mark", function ()
  log.clear()
  log.debug("noise")
  log.error("bad")
  t.equal(#log.lines(), 1)
  t.contains(log.lines()[1], "&red;[Error] bad")
end)

t.test("repeats fold into the newest line", function ()
  log.clear()
  log.info("same") log.info("same") log.info("same")
  t.equal(#log.lines(), 1)
  t.contains(log.lines()[1], "same (x3)")
end)

t.test("only the newest lines are kept", function ()
  log.clear()
  for i = 1, 5 do log.info("line "..i) end
  t.equal(#log.lines(), 3)
  t.contains(log.lines()[3], "line 3")
end)

t.test("the file gets the full date and level", function ()
  os.remove(logPath)
  log.info("to file")
  t.contains(readFile(logPath), "[info] to file")
end)

t.test("a big file is renamed to .old and a new one starts", function ()
  for _ = 1, 40 do log.info(string.rep("x", 40)) end
  t.truthy(#readFile(logPath..".old") > 1024, ".old has the full file")
  t.truthy(#readFile(logPath) < 1024 + 100, "new file is small")
end)

t.test("events log too, and stop removes the listeners", function ()
  log.clear()
  local before = oc.leftovers()
  log.start()
  require("event").push("log_warning", "from an event")
  t.contains(log.lines()[1], "from an event")
  log.stop()
  t.equal(oc.leftovers(), before, "no listeners left")
end)

os.execute('rm -rf "'..folder..'"')
return t.finish()
