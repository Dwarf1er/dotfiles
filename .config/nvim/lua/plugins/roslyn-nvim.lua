vim.pack.add({ "https://github.com/seblyng/roslyn.nvim.git" })

require("roslyn").setup({
	ft = { "cs", "razor" },
})
