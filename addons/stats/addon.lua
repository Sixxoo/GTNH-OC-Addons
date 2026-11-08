return {
  name = "stats",
  version = "1.0.0",
  description = "Counters and readings kept per hour in a file: totals, per hour, last 24 hours, min/max/average, uptime",
  requires = {"clock@1.1"},
  components = {},
  settings = {
    filePath = {default = "stats.dat", description = 'File for the statistics, relative to the program folder; "" keeps them only until the program stops'},
    keepHours = {default = 48, description = "How many hours of history are kept"},
    saveSeconds = {default = 300, description = "How often start() saves the file (also on stop)"},
  },
}
