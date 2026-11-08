return {
  name = "stock-watch",
  version = "1.0.0",
  description = "Watches items and fluids in the ME network against a minimum and maximum, logs when one runs low",
  requires = {"ae2@1"},
  components = {"me_interface", "me_controller"},
  settings = {
    intervalSeconds = {default = 30, description = "How often start() checks the list"},
    watch = {default = {}, description = 'What to watch: {{what = "fluid:water", min = 1000000, max = 32000000, label = "Water"}, ...}'},
    logChanges = {default = true, description = "Log when an entry goes low, empty, back to fine or over its maximum"},
  },
}
