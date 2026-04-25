return {
  {
    "catppuccin/nvim",
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      vim.cmd.colorscheme("catppuccin")
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "#181825" })
    end,
  },
}
