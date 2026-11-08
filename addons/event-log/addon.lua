return {
  name = "event-log",
  version = "1.0.0",
  description = "Log for the screen (coloured, newest first, repeats folded) and a file that rotates",
  requires = {"clock@1"},
  components = {},
  settings = {
    screenLevel = {default = "info", description = "Lowest level shown on the screen: debug, info, warning, error"},
    screenLines = {default = 32, description = "Lines kept for the screen"},
    screenTime = {default = "%H:%M", description = "Time in front of screen lines"},
    tagColors = {default = {}, description = 'Colour of info lines by their start, e.g. {["[QC]"] = "cyan"}'},
    filePath = {default = "/home/logs.log", description = 'Log file; "" is none'},
    fileLevel = {default = "info", description = "Lowest level written to the file"},
    fileTime = {default = "%d.%m.%Y %H:%M:%S", description = "Time in front of file lines"},
    fileMaxKb = {default = 64, description = "Size in KB at which the file is renamed to .old and a new one starts"},
  },
}
