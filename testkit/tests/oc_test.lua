-- The fake OpenOS behaves like OpenComputers where it surprised us in game
local oc = require("testkit.oc")
local t = require("testkit.test")
oc.install()

local event = require("event")
local component = require("component")

t.test("listeners outlive whoever made them, until cancelled", function ()
  local seen = 0
  local id = event.listen("ping", function () seen = seen + 1 end)
  event.push("ping")
  event.push("ping")
  t.equal(seen, 2, "listener calls")
  t.truthy(event.cancel(id), "cancel")
  event.push("ping")
  t.equal(seen, 2, "after cancel")
end)

t.test("event.pull names are patterns: exit also matches thread_exit", function ()
  while event.pull(nil) do end
  event.push("thread_exit")
  t.equal(event.pull("exit"), "thread_exit")
end)

t.test("errors in listeners are caught and logged, not raised", function ()
  local id = event.listen("boom", function () error("bad listener") end)
  event.push("boom")
  event.cancel(id)
  t.contains(oc.log[#oc.log], "bad listener")
end)

t.test("timers run as world time passes, os.sleep moves the clock", function ()
  local runs = 0
  local start = oc.now()
  local id = event.timer(5, function () runs = runs + 1 end, math.huge)
  os.sleep(12)
  t.equal(runs, 2, "runs in 12 s")
  t.equal(oc.now() - start, 12, "clock")
  event.cancel(id)
  t.equal(oc.leftovers(), 0, "nothing left registered")
end)

t.test("transposer quirks: nil tank count, bad index errors, empty tank without amount", function ()
  local address, moves = oc.transposer({
    [0] = {{capacity = 16000}},
    [1] = {{name = "polyaluminiumchloride", amount = 4000000}},
  })
  local transposer = component.proxy(address)

  t.equal(transposer.getTankCount(4), nil, "side without a tank")
  t.equal(transposer.getTankCount(1), 1, "side with a tank")
  t.errors(function () transposer.getFluidInTank(2, 1) end, "invalid tank index")

  local empty = transposer.getFluidInTank(0, 1)
  t.equal(empty.amount, nil, "empty tank amount")
  t.equal(empty.name, nil, "empty tank name")

  local isOk, moved = transposer.transferFluid(1, 0, 900000, 1)
  t.truthy(isOk, "transfer")
  t.equal(moved, 900000, "moved")
  t.equal(moves[1].to, 0, "into the hatch below")
  t.equal(transposer.getFluidInTank(1, 1).amount, 3100000, "left in the tank")
end)

t.test("components: list, get by prefix, proxy, missing component", function ()
  local address = oc.gtMachine("multimachine.purificationplant", {work = true, progress = 100, maxProgress = 2400})
  t.equal(component.type(address), "gt_machine")
  t.equal(component.get(address:sub(1, 6)), address, "prefix")
  t.equal(component.proxy(address).getWorkMaxProgress(), 2400)

  local found = false
  for listed in component.list("gt_machine") do
    if listed == address then found = true end
  end
  t.truthy(found, "listed")

  oc.removeComponent(address)
  t.equal(component.proxy(address), nil, "after removal")
  t.errors(function () component.invoke(address, "hasWork") end, "no such component")
end)

t.test("the screen records cells and can be unbound", function ()
  local gpu, screen = oc.addScreen(20, 3)
  gpu.setForeground(0x00B4FF)
  gpu.setBackground(0x03050A)
  gpu.fill(1, 1, 20, 3, " ")
  gpu.set(2, 2, "┌ NEON ─┐")

  local char, fg, bg = screen.cell(2, 2)
  t.equal(char, "┌", "char")
  t.equal(fg, 0x00B4FF, "foreground")
  t.equal(bg, 0x03050A, "background")
  t.contains(screen.text()[2], "┌ NEON ─┐")
  t.snapshot("neon-box", screen.lines())

  screen.unbind()
  t.equal(gpu.getScreen(), nil, "unbound")
end)

return t.finish()
