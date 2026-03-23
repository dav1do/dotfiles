return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Load luvit types when vim.uv is used
        { path = "luvit-meta/library", words = { "vim%.uv" } },
        -- Load snacks types when Snacks is used
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },
  -- Optional vim.uv type definitions
  { "Bilal2453/luvit-meta", lazy = true },
}
