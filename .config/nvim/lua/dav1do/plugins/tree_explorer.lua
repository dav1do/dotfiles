return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        -- make netrw look like it's enabled so we don't load with with Ex
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        require("nvim-tree").setup({
            filters = {
                dotfiles = true,
            },
            git = {
                ignore = false
            },
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
