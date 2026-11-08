return {
  name = "ore-yield",
  version = "1.0.0",
  description = "How fast items come into the ME network per hour, e.g. ores from miners, void miners or a meteor",
  requires = {"ae2@1", "clock@1.1"},
  components = {"me_interface", "me_controller"},
  settings = {
    filters = {default = {{name = "gregtech:gt.blockores"}}, description = 'What counts, as ae2 filters: {{name = "gregtech:gt.blockores"}, {label = "Raw Gold"}}; each is one cheap network read'},
    windowMinutes = {default = 60, description = "Rates are over this many minutes (shorter = reacts faster, jumps more)"},
    intervalSeconds = {default = 60, description = "How often start() takes a sample"},
  },
}
