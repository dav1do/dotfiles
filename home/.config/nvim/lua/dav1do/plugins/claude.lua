return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for git operations
  },
  config = function()
    require("claude-code").setup({
      window = {
        split_ratio = 0.3,
        position = "vertical",
        enter_insert = true,
        hide_numbers = true,
        hide_signcolumn = true,
      },
      keymaps = {
        toggle = {
          normal = "<leader>cc",
          -- terminal = "<C-o>",
          variants = {
            continue = "<leader>cC",
            verbose = "<leader>cV",
          },
        },
      },
    })

    -- claude-code.nvim renames its buffers to "claude-code" / "claude-code-<id>"
    -- via nvim_buf_set_name / :file, which fires BufFilePost. Matching there
    -- (vs TermOpen + "*claude*") avoids false positives on any path containing
    -- "claude" (e.g. ~/projects/claude-api/, man claude, claude.log).
    vim.api.nvim_create_autocmd("BufFilePost", {
      pattern = "claude-code*",
      callback = function(args)
        if vim.bo[args.buf].buftype ~= "terminal" then
          return
        end
        -- <C-x> exits terminal mode so you can scroll/copy output without
        -- cancelling Claude's process.
        vim.keymap.set("t", "<C-x>", "<C-\\><C-n>", { buffer = args.buf, desc = "Exit terminal mode" })
        -- Normal-mode <C-o> forwards to Claude instead of triggering vim's
        -- jumplist (which shreds the split layout).
        vim.keymap.set("n", "<C-o>", function()
          local id = vim.b.terminal_job_id
          if not id then
            return
          end
          vim.cmd("startinsert")
          vim.api.nvim_chan_send(id, "\x0f") -- ^O
        end, { buffer = args.buf, desc = "Forward <C-o> to Claude" })
      end,
    })
  end,
}
