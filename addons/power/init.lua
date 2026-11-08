-- The computer's own energy. Checks it now and then: warns when low, pushes power_critical when it is
-- about to run out (so a program can put machines in a safe state first), and estimates the time left
-- while it drains. It also writes the time it was last seen running; after a restart it tells when the
-- computer went off without stopping the program (no power, a crash, the chunk unloaded) and for how long
local M = {}

local timer, state, samples, report = nil, "ok", {}, nil

function M.setup(settings)
  M.settings = settings
  state, samples, report = "ok", {}, nil
end

local function clock()
  return require("addons.core").load("clock")
end

---Energy now: {energy, max, fraction, perSecond (negative while draining), secondsLeft (nil when not draining)}
function M.read()
  local computer = require("computer")
  local energy, max = computer.energy(), computer.maxEnergy()
  local now = computer.uptime()
  samples[#samples + 1] = {at = now, energy = energy}

  while #samples > 2 and now - samples[1].at > 120 do
    table.remove(samples, 1)
  end

  local result = {energy = energy, max = max, fraction = max > 0 and energy / max or 0, perSecond = 0}
  local first = samples[1]

  if now - first.at >= 5 then
    result.perSecond = (energy - first.energy) / (now - first.at)

    if result.perSecond < 0 then
      result.secondsLeft = energy / -result.perSecond
    end
  end

  return result
end

---The state of an energy fraction: "ok", "low" or "critical"
function M.state(fraction)
  local percent = fraction * 100

  if percent < M.settings.criticalPercent then
    return "critical"
  elseif percent < M.settings.lowPercent then
    return "low"
  end

  return "ok"
end

---Check once: logs and pushes power_state (state, fraction) and power_critical when it changes
function M.check()
  local event = require("event")
  local result = M.read()
  local new = M.state(result.fraction)
  result.state = new

  if new ~= state then
    local percent = math.floor(result.fraction * 100 + 0.5).."%"

    if new == "critical" then
      event.push("log_error", "[Power] Computer energy critical: "..percent)
      event.push("power_critical", result.fraction)
      event.push("alert_raise", "power", "critical", "Computer energy critical: "..percent)
    elseif new == "low" then
      event.push("log_warning", "[Power] Computer energy low: "..percent)
      event.push("alert_raise", "power", "warning", "Computer energy low: "..percent)
    else
      event.push("log_info", "[Power] Computer energy fine again: "..percent)
      event.push("alert_clear", "power")
    end

    event.push("power_state", new, result.fraction)
    state = new
  end

  M.seen(result.fraction)
  return result
end

---Write "still running" with the energy (done by check)
function M.seen(fraction, clean)
  local path = M.settings.seenFile

  if path == nil or path == "" then
    return
  end

  local file = io.open(path, "w")

  if file ~= nil then
    file:write(string.format("%d %.3f %s\n", clock().now(), fraction or 0, clean and "stopped" or "running"))
    file:close()
  end
end

---What happened since the last run: nil after a clean stop or the first run, else
---{at = last seen (real time), offSeconds, energy = fraction then, text}
function M.lastStop()
  local path = M.settings.seenFile
  local file = path ~= nil and path ~= "" and io.open(path, "r") or nil

  if file == nil then
    return nil
  end

  local line = file:read("*l") or ""
  file:close()
  local at, energy, how = line:match("^(%d+) ([%d%.]+) (%a+)")

  if at == nil or how ~= "running" then
    return nil
  end

  at, energy = tonumber(at), tonumber(energy)
  local off = math.max(0, clock().now() - at)
  local why = energy < (M.settings.criticalPercent / 100 + 0.02) and "out of power" or "power, a crash or the chunk unloading"

  return {at = at, offSeconds = off, energy = energy,
    text = string.format("The computer stopped unexpectedly at %s (energy %d%%, likely %s), off for about %d min",
      clock().format("%d.%m. %H:%M", at), math.floor(energy * 100 + 0.5), why, math.floor(off / 60 + 0.5))}
end

---Report an unexpected stop (logged once), then check every intervalSeconds until stop()
function M.start()
  local event = require("event")
  M.stop()
  report = M.lastStop()

  if report ~= nil then
    event.push("log_warning", "[Power] "..report.text)
  end

  timer = event.timer(M.settings.intervalSeconds, function ()
    local isOk, problem = pcall(M.check)

    if not isOk then
      event.push("log_error", "[Power] "..tostring(problem))
    end
  end, math.huge)

  pcall(M.check)
end

---The report start() found, or nil
function M.report()
  return report
end

---Stop checking and remember that it stopped on purpose
function M.stop()
  if timer ~= nil then
    require("event").cancel(timer)
    timer = nil
    pcall(M.seen, M.read().fraction, true)
  end
end

return M
