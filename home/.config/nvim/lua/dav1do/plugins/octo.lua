return {
  "pwntester/octo.nvim",
  enabled = false, -- replaced by snacks gh
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = "Octo",
  -- stylua: ignore
  keys = {
    -- `only |` closes splits first so the buffer has room to breathe
    { "<leader>lp", "<cmd>only | Octo pr list<cr>",           desc = "PR list" },
    { "<leader>li", "<cmd>only | Octo issue list<cr>",        desc = "Issue list" },
    { "<leader>ln", "<cmd>only | Octo notification list<cr>", desc = "Notifications" },
    { "<leader>lf", "<cmd>Octo search<cr>",                  desc = "Search GitHub" },
    { "<leader>lR", "<cmd>Octo review start<cr>",            desc = "Review files (PR)" },
  },
  opts = {
    picker = "telescope",
    enable_builtin = true,
    -- review comment threads open above the diff instead of below
    reviews = {
      auto_show_threads = true,
    },
  },
}
