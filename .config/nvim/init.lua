-- Core
require("config.globals")
require("config.filetypes")
require("config.options")
require("config.keymap")
require("config.autocmd")

-- Plugins
require("plugins.mason-nvim")
require("plugins.rzls-nvim")
require("plugins.roslyn-nvim")
require("plugins.lualine-nvim")
require("plugins.nvim-treesitter")
require("plugins.onedark-nvim")
require("plugins.telescope-nvim")

-- LSP configuration
require("config.lsp")
