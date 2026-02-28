vim.pack.add({ "https://github.com/folke/snacks.nvim" })

require("snacks").setup({
	image = {
		formats = {
			"png",
			"PNG",
			"jpg",
			"JPG",
			"jpeg",
			"gif",
			"bmp",
			"webp",
			"tiff",
			"heic",
			"HEIC",
			"avif",
			"mp4",
			"mov",
			"avi",
			"mkv",
			"webm",
			"pdf",
		},
		force = true,
		doc = {
			enabled = true,
			inline = true,
			max_width = 40,
			max_height = 80,
			conceal = function(lang, type)
				return type == "image"
			end,
		},
	},
})
