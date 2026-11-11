return {
  name = "installer",
  version = "1.1.0",
  description = "Installs, updates and removes programs in /home/<id>/, keeps their config, update-all for all",
  requires = {"core@1.1", "config@1", "autostart@1"},
  components = {"internet"},
  settings = {},
}
