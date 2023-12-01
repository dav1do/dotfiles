return {
    "nvim-lua/plenary.nvim",                          -- lua functions that many plugins use

    { "christoomey/vim-tmux-navigator", lazy = false }, -- tmux & split window navigation
    {
        "folke/trouble.nvim",
        config = function()
            require("trouble").setup {
                icons = false,
                -- your configuration comes here
                -- or leave it empty to use the default settings
                -- refer to the configuration section below
                vim.keymap.set("n", "<leader>qf", "<cmd>TroubleToggle quickfix<cr>",
                    { silent = true, noremap = true }
                )
            }
        end
    },
    {
        'numToStr/Comment.nvim',
        opts = {},
        lazy = false,
    },
    {
        "akinsho/bufferline.nvim",
        dependencies = "nvim-tree/nvim-web-devicons",
        config = function()
            require('bufferline').setup()
        end
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons', opt = true },
        config = function()
            require("lualine").setup()
        end
    },
    {
        "mbbill/undotree",
        config = function()
            vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
        end

    }, "tpope/vim-fugitive",
    "folke/zen-mode.nvim",
    -- "github/copilot.vim",
}
