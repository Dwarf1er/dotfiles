-- Relative and absolute line numbers
vim.o.number = true
vim.o.relativenumber = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Cursorline
vim.o.cursorline = true

-- OS clipboard
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
	vim.g.clipboard = {
		name = "WslClipboard",
		copy = {
			["+"] = "clip.exe",
			["*"] = "clip.exe",
		},
		paste = {
			["+"] = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).ToString().Replace("`r", ""))',
			["*"] = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).ToString().Replace("`r", ""))',
		},
		cache_enabled = 0,
	}
else
	vim.schedule(function()
	  vim.o.clipboard = 'unnamedplus'
	end)
end

-- Search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Preview substitutions
vim.o.inccommand = "split"

-- Update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Text wrapping
vim.o.wrap = true
vim.o.breakindent = true

-- Tabstops
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

-- Window splitting
vim.o.splitright = true
vim.o.splitbelow = true

-- Save undo history
vim.o.undofile = true

-- Set the default border for all floating windows
vim.o.winborder = "rounded"
