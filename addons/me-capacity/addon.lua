return {
  name = "me-capacity",
  version = "1.0.0",
  description = "Free space on the storage cells in ME Drives (bytes and types), read by transposers next to the drives",
  requires = {},
  components = {"transposer"},
  settings = {
    drives = {default = {}, description = 'Transposers next to ME Drives: {{transposer = "1a2b", side = "north"}, ...}; empty finds every drive next to any transposer'},
    warnPercent = {default = 90, description = "Log a warning when the cells are this full (percent of bytes)"},
    intervalSeconds = {default = 60, description = "How often start() reads the cells"},
  },
}
