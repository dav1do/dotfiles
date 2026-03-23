return {
  "pwntester/octo.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = "Octo",
  -- stylua: ignore
  keys = {
    { "<leader>lp", "<cmd>Octo pr list<cr>",    desc = "PR list" },
    { "<leader>li", "<cmd>Octo issue list<cr>", desc = "Issue list" },
  },
  opts = {
    enable_builtin = true,
  },
}
