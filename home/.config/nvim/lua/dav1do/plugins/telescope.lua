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
            ["q"] = actions.close,
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
    {
      "<leader>ff",
      function()
        require("telescope.builtin").find_files()
      end,
      mode = { "n" },
      desc = "Find files (fast, respects gitignore, includes untracked)",
    },
    {
      "<leader>pf",
      function()
        require("telescope.builtin").find_files({ hidden = true, no_ignore = true })
      end,
      mode = { "n" },
      desc = "Find files (hidden + gitignored)",
    },
    {
      "<leader>fF",
      function()
        require("telescope.builtin").find_files({ hidden = true, no_ignore = true, no_ignore_parent = true })
      end,
      mode = { "n" },
      desc = "Find ALL files (no ignore, nuclear)",
    },
    {
      "<leader>pr",
      "<CMD>Telescope oldfiles<CR>",
      mode = { "n" },
      desc = "Recent files",
    },
    {
      "<C-p>",
      function()
        require("telescope.builtin").find_files()
      end,
      mode = { "n" },
      desc = "Find files (fast, respects gitignore, includes untracked)",
    },
    {
      "<leader>pl",
      "<CMD>Telescope git_status<CR>",
      mode = { "n" },
      desc = "Changed files (git status)",
    },
    {
      "<leader>pg",
      "<CMD>Telescope live_grep<CR>",
      mode = { "n" },
      desc = "Live grep",
    },
    {
      "<leader>pG",
      ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
      mode = { "n" },
      desc = "Live grep with args",
    },
    {
      "<leader>ph",
      "<CMD>Telescope help_tags<CR>",
      mode = { "n" },
      desc = "Help tags",
    },
    {
      "<leader>pk",
      "<CMD>Telescope keymaps<CR>",
      mode = { "n" },
      desc = "Search keymaps",
    },
    {
      "<leader>pp",
      "<CMD>Telescope resume<CR>",
      mode = { "n" },
      desc = "Resume last picker",
    },
    {
      "<leader>pb",
      "<CMD>Telescope buffers<CR>",
      mode = { "n" },
      desc = "Open buffers",
    },
    {
      "<leader>bf",
      "<CMD>Telescope buffers<CR>",
      mode = { "n" },
      desc = "Find buffers",
    },
    {
      "<leader>pq",
      "<cmd>Telescope quickfix<cr>",
      mode = { "n" },
      desc = "Quickfix list",
    },
  },
}
