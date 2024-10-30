return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
  opts = {
    use_diagnostic_signs = true,
    modes = {
      lsp = {
        win = {
          type = "split",     -- split window
          relative = "win",   -- relative to current window
          position = "right", -- right side
          size = 0.3,         -- 30% of the window
        }
      },
      diagnostics = { auto_open = false, },
      preview = {
        type = "split",
        position = "right",
        width = 0.3,
        -- when a buffer is not yet loaded, the preview window will be created
        -- in a scratch buffer with only syntax highlighting enabled.
        -- Set to false, if you want the preview to always be a real loaded buffer.
        scratch = true,
      },
    }
  },
  cmd = "Trouble",
  keys = {
    {
      "<leader>tt",
      "<cmd>Trouble diagnostics toggle focus=false win = { type=split, position=right, width=0.3 } <cr>",

      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>tb",
      "<cmd>Trouble diagnostics toggle filter.buf=0 focus=false win = { type=split, position=right, width=0.3 } <cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>ts",
      "<cmd>Trouble symbols toggle focus=false pinned=true win = { type=split, position=right, relative=win, width=0.3 } <cr>",
      desc = "Symbols (Trouble)",
    },
    {
      "<leader>tl",
      "<cmd>Trouble lsp toggle focus=false <cr>",
      desc = "LSP Definitions / references / ... (Trouble)",
    },
    {
      "<leader>tL",
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List (Trouble)",
    },
    {
      "<leader>tf",
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List (Trouble)",
    },
    {
      "gR",
      "<cmd>Trouble lsp_references<cr>",
      desc = "LSP References (Trouble)",
    },
  }
}
