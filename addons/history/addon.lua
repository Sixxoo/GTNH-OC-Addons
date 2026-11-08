return {
  name = "history",
  version = "1.0.0",
  description = "Long history of values in a file at several resolutions: minutes for hours, quarters for days, hours for a month",
  requires = {"clock@1.1"},
  components = {},
  settings = {
    filePath = {default = "history.dat", description = 'File for the history, relative to the program folder; "" keeps it only while running'},
    levels = {default = {{seconds = 60, keep = 120}, {seconds = 900, keep = 192}, {seconds = 21600, keep = 120}},
      description = "Resolutions: each {seconds per point, points kept}; default 2 hours by minute, 2 days by 15 minutes, 30 days by 6 hours"},
    saveSeconds = {default = 300, description = "How often start() saves the file (also on stop)"},
  },
}
