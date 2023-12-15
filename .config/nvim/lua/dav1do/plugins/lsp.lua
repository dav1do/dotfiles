return {
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v3.x",
        dependencies = {
            -- LSP support
            "neovim/nvim-lspconfig",
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            -- Autocompletion
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "saadparwaiz1/cmp_luasnip",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-nvim-lua",
            "L3MON4D3/LuaSnip",
            --copilot
            "zbirenbaum/copilot.lua",
            "zbirenbaum/copilot-cmp",
            --     "github/copilot.vim",
            -- Snippets
            "rafamadriz/friendly-snippets",
            { "lukas-reineke/lsp-format.nvim", config = true },
        },
        config = function()
            require('copilot').setup({
                panel = { enabled = false },
                suggestion = {
                    enabled = false,
                },
                filetypes = {
                    yaml = true,
                    markdown = true,
                    ["."] = true,
                },
                copilot_node_command = 'node', -- Node.js version must be > 18.x
                server_opts_overrides = {},
            })
            require("copilot_cmp").setup()
            local lsp = require('lsp-zero')
            lsp.preset("recommended")
            lsp.set_preferences({
                sign_icons = {
                    error = 'E',
                    warn = 'W',
                    hint = 'H',
                    info = 'I',
                    Copilot = ''
                }
            })
            lsp.on_attach(function(client, bufnr)
                -- see :help lsp-zero-keybindings
                -- to learn the available actions
                lsp.default_keymaps({ buffer = bufnr })
                -- if lsp.server_capabilities.inlayHintProvider then
                --     -- vim.lsp.buf.inlay_hint(bufnr, true)
                --     vim.lsp.inlay_hint.enable(bufnr, true)
                -- end
            end)
            lsp.setup_servers({ "bashls", "cssls", "dockerls", "jsonls", "lua_ls", "tsserver", "rust_analyzer", "yamlls" })

            require('mason').setup({})
            require('mason-lspconfig').setup({
                ensure_installed = { "bashls", "cssls", "dockerls", "jsonls", "lua_ls", "tsserver", "rust_analyzer", "yamlls" },
                handlers = {
                    lsp.default_setup,
                    lua_ls = function()
                        local lua_opts = lsp.nvim_lua_ls()
                        require('lspconfig').lua_ls.setup(lua_opts)
                    end,
                }
            })

            local cmp = require('cmp')
            local cmp_format = lsp.cmp_format()

            cmp.setup({
                formatting = cmp_format,
                sources = {
                    { name = 'copilot' },
                    { name = 'nvim_lsp' },
                },
                mapping = cmp.mapping.preset.insert({
                    -- scroll up and down the documentation window
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-d>'] = cmp.mapping.scroll_docs(4),
                    ['<M-k>'] = cmp.mapping.select_prev_item(),
                    ['<M-j>'] = cmp.mapping.select_next_item(),

                    -- toggle completion
                    ['<M-u>'] = cmp.mapping.open_docs()
                }),
            })
            lsp.setup()
        end
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup {
                auto_install = false,
                ensure_installed = {
                    "vimdoc", "c", "python", "rust",
                    "json",
                    "javascript",
                    "typescript",
                    "tsx",
                    "yaml",
                    "html",
                    "css",
                    "markdown",
                    "markdown_inline",
                    "graphql",
                    "bash",
                    "lua",
                    "vim",
                    "toml",
                    "dockerfile",
                    "gitignore",
                    "query",
                },
                ident = { enable = true },
                rainbow = {
                    enable = true,
                    extended_mode = true,
                    max_file_lines = nil,
                },
                highlight = { enable = true,
                    additional_vim_regex_highlighting = false,
                    disable = function(lang, buf)
                        local max_filesize = 1000 * 1024 -- 1 MB
                        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                    end, }
            }
        end
    },
    "nvim-treesitter/nvim-treesitter-context",
    "nvim-treesitter/playground",
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

}
