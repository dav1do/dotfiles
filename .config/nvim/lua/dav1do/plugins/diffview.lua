return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function(_, opts)
    -- Suppress spurious "Failed to create diff buffer" for LOCAL:/REMOTE: virtual
    -- files — diffview recovers and shows the diff correctly, it's just noise.
    local orig_notify = vim.notify
    vim.api.nvim_create_autocmd("User", {
      pattern = "DiffviewViewOpened",
      once = false,
      callback = function()
        vim.notify = function(msg, level, o)
          if type(msg) == "string" and msg:match("Failed to create diff buffer") then return end
          orig_notify(msg, level, o)
        end
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = "DiffviewViewClosed",
      once = false,
      callback = function() vim.notify = orig_notify end,
    })
    require("diffview").setup(opts)
  end,
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
    "DiffviewFileHistory",
  },
  -- stylua: ignore
  keys = {
    { "<leader>ld", "<cmd>DiffviewOpen<cr>",           desc = "Diff view (changes)" },
    { "<leader>lx", "<cmd>DiffviewClose<cr>",          desc = "Close diff view" },
    { "<leader>lh", "<cmd>DiffviewFileHistory %<cr>",  desc = "File history" },
    { "<leader>lH", "<cmd>DiffviewFileHistory<cr>",    desc = "Repo history" },
  },
  opts = {
    keymaps = {
      view = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
      file_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
      file_history_panel = {
        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
    },
  },
}
