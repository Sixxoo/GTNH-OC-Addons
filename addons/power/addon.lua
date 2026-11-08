return {
  name = "power",
  version = "1.0.0",
  description = "The computer's own power: warns before it runs out, and tells after a restart when and how it went off",
  requires = {"clock@1.1"},
  components = {},
  settings = {
    lowPercent = {default = 25, description = "Warn when the computer's energy is under this percent"},
    criticalPercent = {default = 10, description = "Critical under this percent (push power_critical so the program can switch machines off safely)"},
    intervalSeconds = {default = 10, description = "How often start() checks the energy"},
    seenFile = {default = ".power-seen", description = 'File (in the program folder) that remembers when the program last ran, to report an unexpected stop; "" = off'},
  },
}
