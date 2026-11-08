-- Groups of the catalog in README.md, in this order. Every addon belongs to one group;
-- groups without addons yet are not shown
return {
  {name = "Base", description = "Loading, installing, settings, starting, staying up", addons = {"core", "installer", "config", "autostart", "recovery"}},
  {name = "Monitor Screen", description = "The neon look, drawing it, time and the event log on the screen", addons = {"neon-ui", "screen", "clock", "event-log"}},
  {name = "Machines", description = "GregTech machines and transposers", addons = {"gt-machine", "transposer"}},
  {name = "Safety", description = "Alerts, power and checks that catch problems early", addons = {}},
  {name = "ME System features", description = "Stock, crafting and storage of the ME network", addons = {"ae2", "stock-watch", "cpu-monitor", "craft-history", "me-capacity", "ore-yield"}},
  {name = "OC Network", description = "Computers talking to each other", addons = {}},
}
