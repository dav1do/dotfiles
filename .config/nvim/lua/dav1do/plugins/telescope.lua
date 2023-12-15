return {
    'nvim-telescope/telescope.nvim',
    -- branch = '0.1.x',
    tag = "0.1.4",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },

        {
            "SmiteshP/nvim-navbuddy",
            dependencies = {
                "SmiteshP/nvim-navic",
                "MunifTanjim/nui.nvim"
            },
            opts = { lsp = { auto_attach = true } }
        }
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local trouble = require("trouble.providers.telescope")

        telescope.setup({
            defaults = {
                path_display = { "truncate " },
                mappings = {
                    i = {
                        ["<esc>"] = actions.close,
                        ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                        ["<c-t>"] = trouble.open_with_trouble
                    },
                    n = { ["<c-t>"] = trouble.open_with_trouble },
                },
            },
        })
        telescope.load_extension("fzf")

        --   function find_files_from_project_git_root()
        --     local function is_git_repo()
        --         vim.fn.system("git rev-parse --is-inside-work-tree")
        --         return vim.v.shell_error == 0
        --     end
        --     local function get_git_root()
        --         local dot_git_path = vim.fn.finddir(".git", ".;")
        --         return vim.fn.fnamemodify(dot_git_path, ":h")
        --     end
        --     local opts = {}
        --     if is_git_repo() then
        --         opts = {
        --             cwd = get_git_root(),
        --         }
        --     end
        --     require("telescope.builtin").find_files(opts)
        -- end

        -- vim.keymap.set("n", "<leader>pf", "<cmd>find_files_from_project_git_root<cr>")
    end,
    keys = {
        { "<leader>pf", "<CMD>Telescope find_files<CR>", mode = {  "n" } },
        { "<leader>pfa", "<CMD>Telescope find_files hidden=true<CR>", mode = { "n" } },
        { "<leader>pr", "<CMD>Telescope oldfiles<CR>",   mode = { "n" } },
        { "<C-p>",      "<CMD>Telescope git_files<CR>",  mode = { "n" } },
        { "<leader>ps", "<CMD>Telescope live_grep<CR>",  mode = { "n" } },
    },
}
