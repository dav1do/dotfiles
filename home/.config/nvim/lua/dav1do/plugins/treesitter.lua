return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  config = function()
    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")

    -- configure treesitter
    treesitter.setup({ -- enable syntax highlighting
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        -- disable = function(lang, buf)
        --     local max_filesize = 1000 * 1024 -- 1 MB
        --     local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        --     if ok and stats and stats.size > max_filesize then
        --         return true
        --     end
        -- end,
      },
      -- enable indentation
      indent = { enable = true },
      -- enable autotagging (w/ nvim-ts-autotag plugin)
      autotag = {
        enable = true,
      },
      -- ensure these language parsers are installed
      ensure_installed = {
        "bash",
        "c",
        "css",
        "dockerfile",
        "gitignore",
        "go",
        "graphql",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown_inline",
        "markdown",
        "python",
        "query",
        "regex",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>",
          node_incremental = "<CR>",
          scope_incremental = "<Tab>", -- bigger jump: next syntactic scope
          node_decremental = "<BS>",
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- jump forward to textobj if not under cursor
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "around function" },
            ["if"] = { query = "@function.inner", desc = "inner function" },
            ["ac"] = { query = "@class.outer", desc = "around class/impl" },
            ["ic"] = { query = "@class.inner", desc = "inner class/impl" },
            ["aa"] = { query = "@parameter.outer", desc = "around argument" },
            ["ia"] = { query = "@parameter.inner", desc = "inner argument" },
            ["ab"] = { query = "@block.outer", desc = "around block" },
            ["ib"] = { query = "@block.inner", desc = "inner block" },
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- adds to jumplist so <C-o>/<C-i> can go back
          goto_next_start = {
            ["]f"] = { query = "@function.outer", desc = "Next function" },
            ["]i"] = { query = "@class.outer", desc = "Next impl/class" },
            ["]a"] = { query = "@parameter.inner", desc = "Next argument" },
          },
          goto_next_end = {
            ["]F"] = { query = "@function.outer", desc = "Next function end" },
            ["]I"] = { query = "@class.outer", desc = "Next impl/class end" },
          },
          goto_previous_start = {
            ["[f"] = { query = "@function.outer", desc = "Prev function" },
            ["[i"] = { query = "@class.outer", desc = "Prev impl/class" },
            ["[a"] = { query = "@parameter.inner", desc = "Prev argument" },
          },
          goto_previous_end = {
            ["[F"] = { query = "@function.outer", desc = "Prev function end" },
            ["[I"] = { query = "@class.outer", desc = "Prev impl/class end" },
          },
        },
      },
    })
  end,
}
