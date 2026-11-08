-- Copy this folder to addons/<name>/ and fill it in. See FORMAT.md
return {
  name = "_template",
  version = "0.1.0",
  description = "One line in English: what the addon does",
  requires = {},            -- e.g. {"clock@1"}
  components = {},          -- e.g. {"gpu", "screen"}
  settings = {
    -- example = {default = 10, description = "What it changes, with its unit"},
  },
}
