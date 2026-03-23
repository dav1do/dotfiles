return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    -- disabled — already handled by existing plugins
    bigfile      = { enabled = false },
    dashboard    = { enabled = false },
    explorer     = { enabled = false },
    input        = { enabled = false },
    notifier     = { enabled = false },
    picker       = { enabled = false },
    quickfile    = { enabled = false },
    scroll       = { enabled = false },
    statuscolumn = { enabled = false },
    terminal     = { enabled = false },
    zen          = { enabled = false },

    -- enabled
    gitbrowse = { enabled = true },
    bufdelete = { enabled = true },
    animate   = { enabled = false }, -- animations cause lag on every cursor move
    words     = { enabled = true },
    indent    = {
      enabled = true,
      indent  = { char = "│" },
      scope   = { enabled = true, char = "│" },
      animate = { enabled = false },
    },
  },
  -- stylua: ignore
  keys = {
    { "<leader>lo", function() Snacks.gitbrowse() end, desc = "Open in browser (GitHub)", mode = { "n", "v" } },
    { "<leader>bd", function()
      local ft = vim.bo.filetype
      -- dadbod sets b:dbui_db_key_name on all its managed SQL buffers
      local is_dadbod_buf = ft == "dbui" or ft == "dbout"
        or (ft == "sql" and vim.b.dbui_db_key_name ~= nil)
      if is_dadbod_buf then
        -- Close the window entirely (not just delete buffer) so layout stays intact
        local buf = vim.api.nvim_get_current_buf()
        pcall(function() vim.cmd("close") end)
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      else
        -- force-close tool buffers (nofile, help, etc.) without save prompt
        Snacks.bufdelete({ force = vim.bo.buftype ~= "" })
      end
    end, desc = "Delete buffer" },
    { "]w",         function() Snacks.words.jump(1, true) end,  desc = "Next word reference" },
    { "[w",         function() Snacks.words.jump(-1, true) end, desc = "Prev word reference" },
  },
}
