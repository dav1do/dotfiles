return {
    "nvim-lua/plenary.nvim",                            -- lua functions that many plugins use
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

    },
    {
        "tpope/vim-fugitive",
        config = function()
            vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
        end
    },
    "folke/zen-mode.nvim",
    -- {
    --     "anuvyklack/pretty-fold.nvim",
    --     lazy = false,
    --     config = function()
    --         require("pretty-fold").setup()
    --     end
    -- },
    -- {
    --     'mrcjkb/rustaceanvim',
    --     version = '^3', -- Recommended
    --     ft = { 'rust' },
    -- },
    {
        'saecki/crates.nvim',
        tag = 'stable',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            require('crates').setup()
        end,
    },
    {
        "rust-lang/rust.vim",
        ft = "rust",
        init = function()
            vim.g.rustfmt_autosave = 1
        end
    },
    {
        "max397574/better-escape.nvim",
        config = function()
            require("better_escape").setup()
        end,
    },
    -- "github/copilot.vim",
}
