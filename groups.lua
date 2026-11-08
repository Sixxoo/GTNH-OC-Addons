-- Groups of the catalog in README.md, in this order. Every addon belongs to one group
return {
  {name = "Base", description = "Loading, installing, settings, starting, staying up", addons = {"core", "installer", "config", "autostart", "recovery"}},
  {name = "Screen", description = "The neon look and drawing it", addons = {"neon-ui", "screen"}},
  {name = "Time and logs", addons = {"clock", "event-log"}},
  {name = "Machines", description = "GregTech machines and transposers", addons = {"gt-machine", "transposer"}},
}
