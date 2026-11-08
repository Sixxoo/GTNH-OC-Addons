local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local addons = require("addons.core")
local cfg = addons.load("config")

local schema = cfg.table({
  mode = cfg.enum({"multiThread", "singleThreadBalancing"}),
  floorQty = cfg.number({min = 0, default = 0}),
  me = cfg.address(),
  t3 = cfg.table({
    enable = cfg.boolean(),
    hatchSide = cfg.side({default = "up"}),
  }),
  limits = cfg.map(cfg.number({min = 0})),
})

local address = "261af9d4-a03b-4b15-b1f0-ddbcda629cf7"

t.test("a good config: defaults filled, enum spelled as listed, side as a number", function ()
  local config, problems, warnings = cfg.check({mode = "SINGLETHREADBALANCING", me = address,
    t3 = {enable = true, hatchSide = "down"}, limits = {t1 = 32e6}}, schema)
  t.equal(#problems, 0, "problems")
  t.equal(#warnings, 0, "warnings")
  t.equal(config.mode, "singleThreadBalancing")
  t.equal(config.floorQty, 0, "default")
  t.equal(config.t3.hatchSide, 0, "down is 0")
end)

t.test("every mistake is listed with its path and what would work", function ()
  local _, problems = cfg.check({mode = "fast", floorQty = -1, me = "261af9d4",
    t3 = {enable = "yes", hatchSide = "dwon"}, limits = {t1 = "lots"}}, schema)
  local all = table.concat(problems, "\n")
  t.equal(#problems, 6, "problems: "..all)
  t.contains(all, 'mode: is "fast", use one of: "multiThread", "singleThreadBalancing"')
  t.contains(all, "floorQty: must be at least 0")
  t.contains(all, "me: must be a full address")
  t.contains(all, "t3.enable: must be true or false")
  t.contains(all, 't3.hatchSide: is "dwon"')
  t.contains(all, "limits.t1: must be a number")
end)

t.test("missing settings and unknown ones", function ()
  local _, problems, warnings = cfg.check({mode = "multiThread", t3 = {enable = false}, extra = 1, limits = {}}, schema)
  t.equal(problems[1], "me: missing")
  t.equal(warnings[1], "extra: unknown setting, ignored")
end)

t.test("a check function can compare settings", function ()
  local s = cfg.table({low = cfg.number(), high = cfg.number({check = function (value, root)
    return value > root.low, "must be above low"
  end})})
  local _, problems = cfg.check({low = 5, high = 3}, s)
  t.equal(problems[1], "high: must be above low")
end)

local folder = os.tmpname()
os.remove(folder)
os.execute('mkdir -p "'..folder..'"')
local path = folder.."/config.lua"

local function write(text)
  local file = io.open(path, "w") file:write(text) file:close()
end

t.test("load reads the file in a sandbox and errors with every mistake", function ()
  write('return {mode = "multiThread", me = "'..address..'", t3 = {enable = true}, limits = {}}')
  t.equal(cfg.load(path, schema).mode, "multiThread")

  write('return {mode = "x", t3 = {enable = true}, limits = {}}')
  t.errors(function () cfg.load(path, schema) end, "me: missing")

  write('os.remove("/home") return {}')
  t.errors(function () cfg.load(path, schema) end, "[config]")
end)

t.test("edit opens the editor, then checks what was saved", function ()
  write('return {mode = "x"}')
  package.loaded.shell.execute = function (command)
    t.equal(command, "edit "..path)
    write('return {mode = "multiThread", me = "'..address..'", t3 = {enable = true}, limits = {}}')
  end
  local config, problems = cfg.edit(path, schema)
  t.equal(#problems, 0)
  t.equal(config.mode, "multiThread")

  package.loaded.shell.execute = function () write('return {mode = ') end
  config, problems = cfg.edit(path, schema)
  t.equal(config, nil, "a broken file gives nil")
  t.truthy(#problems == 1, "and the reason")
end)

t.test("merge keeps the new layout and comments with the old values", function ()
  local old = [[
local config = {
  mode = "multiThread", -- old comment
  limit = 99,
  gone = true,
}
return config
]]
  local new = [[
local config = {
  mode = "singleThread", -- How units run
  limit = 32, -- Litres
  floor = 5, -- New setting
}
return config
]]
  local merged, report = cfg.merge(old, new, {whenMissing = {{pattern = "^floor$", value = 0, why = "0 is off, as before"}}})
  t.contains(merged, 'mode = "multiThread", -- How units run')
  t.contains(merged, "limit = 99, -- Litres")
  t.contains(merged, "floor = 0, -- New setting")
  t.equal(report.carried, 2)
  t.equal(report.removed[1], "gone")
  t.contains(table.concat(cfg.describe(report), "\n"), "0 is off, as before")
end)

t.test("merge works with a file that starts with return {", function ()
  local merged = cfg.merge('return {\n  a = 1,\n}\n', 'return {\n  a = 2, -- A\n  b = 3,\n}\n')
  t.contains(merged, "a = 1, -- A")
  t.contains(merged, "b = 3,")
end)

os.execute('rm -rf "'..folder..'"')
return t.finish()
