-- Linux/MacOS:
vim.cmd("set runtimepath+=~/.config/nvim")
-- Windows:
-- vim.cmd("set runtimepath+=%USERPROFILE%\\AppData\\Local\\nvim")

require("user.core.mappings")
require("user.core.autocmds")
require("user.core.settings")
require("user.lazyconfig")
require("user.lspconfig")
require("user.plugins.config.telescope-nvim-config")
require("user.plugins.config.nvim-treesitter-config")
require("user.plugins.config.nvim-cmp-config")
