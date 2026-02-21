-- Core
require("config.globals")
require("config.filetypes")
require("config.options")
require("config.keymap")
require("config.autocmd")
require("config.commands")

-- Plugins
require("plugins.mason-nvim")
require("plugins.roslyn-nvim")
require("plugins.lualine-nvim")
require("plugins.nvim-treesitter")
require("plugins.onedark-nvim")
require("plugins.telescope-nvim")
require("plugins.nvim-dap")
require("plugins.conform-nvim")
require("plugins.nvim-cmp")
require("plugins.autoclose-nvim")
require("plugins.markdown-toc-nvim")

-- LSP configuration
require("config.lsp")
