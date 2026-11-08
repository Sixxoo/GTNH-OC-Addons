return {
  name = "central-server",
  version = "1.0.0",
  description = "One computer sees all others: each program reports its status, the server lists them and notices when one goes quiet",
  requires = {"network@1"},
  components = {"modem"},
  settings = {
    name = {default = "", description = "Name this computer reports under; empty = the computer's label, else its address"},
    reportSeconds = {default = 30, description = "How often a client reports its status"},
    offlineSeconds = {default = 120, description = "A computer not heard from for this long counts as offline"},
  },
}
