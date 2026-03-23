return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require("lualine").setup({
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = { "filename" },
        lualine_x = {
          -- Noice recording/macro indicator
          {
            function() return require("noice").api.statusline.mode.get() end,
            cond = function() return require("noice").api.statusline.mode.has() end,
            color = { fg = "#ff9e64" },
          },
          -- Overseer task status
          "overseer",
          -- LSP diagnostics: errors and warnings only (hints are noise)
          {
            "diagnostics",
            sources = { "nvim_lsp" },
            sections = { "error", "warn" },
            symbols = {
              error = " ",
              warn = " ",
            },
            colored = true,
            update_in_insert = false,
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    })
  end
}
