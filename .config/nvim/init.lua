-- Linux/MacOS: vim.cmd("set runtimepath+=~/.config/nvim")
-- Windows:
vim.cmd("set runtimepath+=%USERPROFILE%\\AppData\\Local\\nvim")

require("settings")

require("mappings")

require("autocmds")

require("plugins")

require("lsp")
