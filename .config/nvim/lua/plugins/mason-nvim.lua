vim.pack.add({ "https://github.com/mason-org/mason.nvim.git" })

require("mason").setup({
    registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry"
    }
})
