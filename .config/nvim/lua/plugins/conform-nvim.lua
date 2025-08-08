vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

local conform = require("conform")
local mason_bin = vim.fn.expand("$MASON/bin")

conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		cs = { "csharpier" },
	},
	formatters = {
		csharpier = {
			command = mason_bin .. "/" .. "csharpier",
			args = {
				"format",
				"--write-stdout",
			},
			to_stdin = true,
		},
	},
	format_on_save = {
		lsp_fallback = true,
		async = false,
		timeout_ms = 500,
	},
})

vim.keymap.set({ "n", "v" }, "<leader>mp", function()
	conform.format({
		lsp_fallback = true,
		async = false,
		timeout_ms = 500,
	})
end)
