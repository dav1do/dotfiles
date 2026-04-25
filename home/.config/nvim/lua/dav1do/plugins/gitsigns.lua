return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = true, -- on by default
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- hunk navigation
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, { desc = "Next hunk" })
        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, { desc = "Prev hunk" })

        -- hunk operations
        map("n", "<leader>ls", gitsigns.stage_hunk, { desc = "Stage hunk" })
        map("v", "<leader>ls", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Stage hunk" })
        map("n", "<leader>lu", gitsigns.undo_stage_hunk, { desc = "Undo stage hunk" })
        map("n", "<leader>lr", gitsigns.reset_hunk, { desc = "Reset hunk" })
        map("n", "<leader>lv", gitsigns.preview_hunk, { desc = "Preview hunk" })

        -- blame
        map("n", "<leader>lb", gitsigns.toggle_current_line_blame, { desc = "Toggle line blame" })
        map("n", "<leader>lB", function()
          gitsigns.blame_line({ full = true })
        end, { desc = "Blame line (full)" })
      end,
    },
  },
}
