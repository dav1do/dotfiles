return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
    {
      "SmiteshP/nvim-navbuddy",
      dependencies = {
        "SmiteshP/nvim-navic",
        "MunifTanjim/nui.nvim",
      },
      opts = { lsp = { auto_attach = true } },
    },
    {
      "nvim-telescope/telescope-live-grep-args.nvim",
      -- This will not install any breaking changes.
      -- For major updates, this must be adjusted manually.
      version = "^1.0.0",
    },
    -- replaces vim.ui.select globally (fixes octo numbered prompts, etc.)
    "nvim-telescope/telescope-ui-select.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local lga_actions = require("telescope-live-grep-args.actions")
    local actions = require("telescope.actions")
    local open_with_trouble = require("trouble.sources.telescope").open

    telescope.setup({
      defaults = {
        path_display = { shorten = 8 }, --" truncate" ?
        -- always exclude heavy build/dep dirs, even in no_ignore mode (<leader>pff)
        file_ignore_patterns = { "^target/", "^node_modules/", "^%.git/" },
        mappings = {
          i = {
            -- <Esc> goes to normal mode (j/k navigation, ?, q to close)
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<c-t>"] = open_with_trouble,
          },
          n = {
            ["q"]     = actions.close,
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<c-t>"] = open_with_trouble,
          },
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
        live_grep_args = {
          auto_quoting = true,
          mappings = {
            n = {
              ["<leader>pss"] = lga_actions.quote_prompt({ postfix = " --hidden" }),
            },
          },
        },
      },
    })
    telescope.load_extension("fzf")
    telescope.load_extension("live_grep_args")
    telescope.load_extension("ui-select")

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
    { "<leader>pf", "<CMD>Telescope find_files hidden=true<CR>", mode = { "n" } },
    { "<leader>ff", "<CMD>Telescope find_files <CR>", mode = { "n" } },
    { "<leader>pff", "<CMD>Telescope find_files hidden=true no_ignore=true no_ignore_parent=true<CR>", mode = { "n" } },
    { "<leader>pr", "<CMD>Telescope oldfiles<CR>", mode = { "n" } },
    { "<C-p>",      "<CMD>Telescope git_files<CR>",   mode = { "n" }, desc = "Git files" },
    { "<leader>pg", "<CMD>Telescope git_status<CR>", mode = { "n" }, desc = "Changed files (git)" },
    { "<leader>ps", "<CMD>Telescope live_grep<CR>", mode = { "n" } },
    { "<leader>pss", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", mode = { "n" } },
    { "<leader>ph",  "<CMD>Telescope help_tags<CR>",  mode = { "n" } },
    { "<leader>pk",  "<CMD>Telescope keymaps<CR>",   mode = { "n" }, desc = "Search keymaps" },
    { "<leader>pp",  "<CMD>Telescope resume<CR>",    mode = { "n" }, desc = "Resume last picker" },
    { "<leader>pb", "<CMD>Telescope buffers<CR>", mode = { "n" } },
    {
      "<leader>bf",
      "<CMD>Telescope buffers<CR>",
      mode = { "n" },
      desc = "Find buffers",
    },
    {
      "<leader>pq",
      "<cmd>Telescope quickfix<cr>",
      desc = "Quickfix List",
    },
  },
}
