return {
  name = "cpu-monitor",
  version = "1.0.0",
  description = "Crafting CPUs of the ME network: busy or free, what each crafts and for how long, logs jobs",
  requires = {"ae2@1"},
  components = {"me_interface", "me_controller"},
  settings = {
    intervalSeconds = {default = 5, description = "How often start() looks at the CPUs"},
    logJobs = {default = true, description = "Log when a CPU starts and finishes a job"},
  },
}
