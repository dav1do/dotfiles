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
          terminal = "<C-o>",
          variants = {
            continue = "<leader>cC",
            verbose = "<leader>cV",
          },
        },
      },
    })

    -- Esc exits terminal mode in the Claude buffer only, so you can navigate
    -- output in normal mode without accidentally cancelling Claude's process.
    -- Other terminal buffers (lazygit, shell, etc.) are unaffected.
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*claude*",
      callback = function(args)
        vim.keymap.set("t", "<C-x>", "<C-\\><C-n>", { buffer = args.buf, desc = "Exit terminal mode" })
      end,
    })
  end,
}
