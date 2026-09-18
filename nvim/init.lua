-- Entry point. Order matters: options set the leader keys, and lazy.nvim
-- captures them at setup time, so options must come first.
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
