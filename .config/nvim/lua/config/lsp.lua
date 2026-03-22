vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local opts = { buffer = ev.buf }
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "gdscript",
	callback = function()
		vim.lsp.start({
			name = "godot",
			cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
			root_dir = vim.fs.root(0, { "project.godot" }),
		})
	end,
})

-- Diagnostics
vim.diagnostic.config({
	virtual_lines = {
		current_line = true,
	},
})
