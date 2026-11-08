return {
  name = "clock",
  version = "1.1.0",
  description = "Real time with a time zone (not game time), cheap to call often",
  requires = {},
  components = {},
  settings = {
    timeZone = {default = 0, description = "Hours from UTC, e.g. 1 for Prague in winter, 2 in summer", ask = "Time zone, hours from UTC (1 = Prague in winter)"},
    readSeconds = {default = 30, description = "Seconds between reads of the real clock; in between it counts on"},
    tmpFile = {default = "/tmp/clock.tmp", description = "File written to read the real time"},
  },
}
