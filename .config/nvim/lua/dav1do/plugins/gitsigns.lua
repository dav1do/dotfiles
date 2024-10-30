return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>h", group = "gitsigns" },
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require('gitsigns')

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end
        gitsigns.toggle_current_line_blame() -- on by default

        map('n', '<leader>lb', gitsigns.toggle_current_line_blame, { desc = "toggle line blame" })
        map('n', '<leader>lB', function() gitsigns.blame_line { full = true } end, { desc = "blame line" })
      end,
    },
  }
}
