vim.pack.add({ "https://github.com/sotte/presenting.nvim" })

local Presenting = require("presenting")

local ui_state = nil

local function disable_ui()
	if ui_state then
		return
	end

	ui_state = {
		showtabline = vim.o.showtabline,
		laststatus = vim.o.laststatus,
		ruler = vim.o.ruler,
		cmdheight = vim.o.cmdheight,
		number = vim.wo.number,
		relativenumber = vim.wo.relativenumber,
		signcolumn = vim.wo.signcolumn,
	}

	vim.o.showtabline = 0
	vim.o.laststatus = 0
	vim.o.cmdheight = 0
	vim.o.ruler = false
	vim.wo.number = false
	vim.wo.relativenumber = false
	vim.wo.signcolumn = "no"
end

local function restore_ui()
	if not ui_state then
		return
	end

	vim.o.showtabline = ui_state.showtabline
	vim.o.laststatus = ui_state.laststatus
	vim.o.cmdheight = ui_state.cmdheight
	vim.o.ruler = ui_state.ruler
	vim.wo.number = ui_state.number
	vim.wo.relativenumber = ui_state.relativenumber
	vim.wo.signcolumn = ui_state.signcolumn

	ui_state = nil
end

Presenting.setup({
	cmd = { "Presenting" },
	options = { width = 120 },
	keymaps = {
		["n"] = Presenting.next,
		["p"] = Presenting.prev,
		["<CR>"] = Presenting.next,
		["<BS>"] = Presenting.prev,
		["<Right>"] = Presenting.next,
		["<Left>"] = Presenting.prev,
		["f"] = Presenting.first,
		["l"] = Presenting.last,
		["<Home>"] = Presenting.first,
		["<End>"] = Presenting.last,
		["q"] = function()
			Presenting.quit()
			restore_ui()
		end,
	},
})

vim.api.nvim_create_user_command("PresentingStart", function()
	disable_ui()
	Presenting.start()
end, {})

vim.api.nvim_create_user_command("PresentingStop", function()
	Presenting.quit()
	restore_ui()
end, {})
