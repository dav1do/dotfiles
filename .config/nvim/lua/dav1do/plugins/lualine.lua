return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require("lualine").setup({
      sections = {
        -- mode + macro recording side-by-side so you can't miss either
        lualine_a = {
          "mode",
          {
            function() return " REC @" .. vim.fn.reg_recording() end,
            cond = function() return vim.fn.reg_recording() ~= "" end,
            color = { fg = "#000000", bg = "#ff9e64", gui = "bold" },
          },
        },
        lualine_b = { "branch", "diff" },
        lualine_c = { "filename" },
        lualine_x = {
          -- noice mode (command-line messages like :%s/ confirmation prompts)
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
