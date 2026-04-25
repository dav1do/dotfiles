-- Dadbod disabled — using psql / DBeaver outside nvim for now.
-- SQL syntax highlighting is handled by Neovim's built-in ftplugin
-- (and treesitter if the `sql` parser is installed), not by dadbod.
-- Flip `enabled = false` back to remove (or delete this file) to re-enable.
return {
  {
    "tpope/vim-dadbod",
    enabled = false,
    lazy = true,
    ft = { "sql", "mysql", "plsql" },
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    enabled = false,
    dependencies = {
      "tpope/vim-dadbod",
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>B", "<cmd>DBUIToggle<cr>", desc = "Database UI" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_disable_info_notifications = 1
      vim.g.db_ui_use_nvim_notify = 1
      vim.g.db_ui_execute_on_save = 0
      vim.g.db_ui_winwidth = 30
      vim.g.db_ui_env_variable_url = "DATABASE_URL"
    end,
    config = function()
      -- Result window: focus it when it opens, q to close
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "dbout",
        callback = function(e)
          vim.schedule(function()
            local wins = vim.fn.win_findbuf(e.buf)
            if wins[1] then
              vim.api.nvim_set_current_win(wins[1])
            end
          end)
          vim.keymap.set("n", "q", "<C-w>c", { buffer = e.buf, nowait = true, desc = "Close result window" })
        end,
      })

      -- Sidebar: fix width, q to close
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "dbui",
        callback = function(e)
          vim.wo.winfixwidth = true
          vim.keymap.set("n", "q", "<cmd>DBUIToggle<cr>", { buffer = e.buf, nowait = true, desc = "Close DB UI" })
        end,
      })

      -- SQL completion
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          local ok, cmp = pcall(require, "cmp")
          if not ok then
            return
          end
          cmp.setup.buffer({
            sources = {
              { name = "vim-dadbod-completion" },
              { name = "nvim_lsp" },
              { name = "luasnip" },
              { name = "buffer" },
            },
          })
        end,
      })
    end,
  },
}
