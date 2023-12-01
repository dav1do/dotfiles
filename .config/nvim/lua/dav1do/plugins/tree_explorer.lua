return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        require("nvim-tree").setup({
            actions = {
                open_file = {
                    window_picker = {
                        enable = false,
                    }
                }
            }
        })
        vim.keymap.set({ "n", "i" }, "<C-e>", "<cmd>NvimTreeOpen<cr>")
    end,
}
