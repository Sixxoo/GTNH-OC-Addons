return {
  name = "craft-history",
  version = "1.0.0",
  description = "Keeps finished crafting jobs (from cpu-monitor) in a file: recent jobs and totals per item",
  requires = {"cpu-monitor@1", "clock@1.1"},
  components = {},
  settings = {
    filePath = {default = "craft-history.log", description = 'File for the jobs, relative to the program folder; "" keeps them only in memory'},
    fileMaxKb = {default = 32, description = "Size in KB at which the file is renamed to .old and a new one starts"},
    keep = {default = 200, description = "How many jobs are kept in memory for recent() and stats()"},
  },
}
