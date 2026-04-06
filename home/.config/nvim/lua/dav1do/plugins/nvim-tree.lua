return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    --vim.g.nvim_tree_auto_close = 1
    require("nvim-tree").setup({
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        -- apply all default nvim-tree keymaps first
        api.config.mappings.default_on_attach(bufnr)
        -- q closes tree (consistent with all other tool panels)
        vim.keymap.set("n", "q", api.tree.close, { buffer = bufnr, nowait = true, desc = "Close tree" })
        -- remove nvim-tree's s (system open) so Flash jump works inside the tree
        pcall(vim.keymap.del, "n", "s", { buffer = bufnr })
      end,
      view = {
        width = 35,
        relativenumber = true,
      },
      -- change folder arrow icons
      renderer = {
        indent_markers = {
          enable = true,
        },
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "", -- arrow when folder is closed
              arrow_open = "", -- arrow when folder is open
            },
          },
        },
      },
      actions = {
        open_file = {
          -- When only one eligible window exists the picker is silent (no UI).
          -- When multiple code windows are open it prompts. Utility windows
          -- (results, sidebar, quickfix, etc.) are excluded so files never
          -- accidentally open in a dadbod result split or similar.
          window_picker = {
            enable = true,
            picker = "default",
            exclude = {
              filetype = { "dbout", "dbui", "trouble", "qf", "diff",
                           "fugitive", "fugitiveblame", "notify" },
              buftype  = { "terminal", "nofile", "help" },
            },
          },
        },
      },
      update_focused_file = { enable = true, },
      filters = {
        dotfiles = false,
        git_ignored = false,
        custom = { ".DS_Store" },
      },
      git = {
        ignore = false,
      },
    })

    -- Keep sidebar width stable — prevent Neovim from stealing/giving columns
    -- when other splits open/close alongside the tree.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "NvimTree",
      callback = function() vim.wo.winfixwidth = true end,
    })

    -- set keymaps
    local keymap = vim.keymap
    local skip_ft = { NvimTree = true, dbout = true, dbui = true, trouble = true, OverseerList = true }
    keymap.set("n", "<C-e>", function()
      local api = require("nvim-tree.api")
      -- If currently in a utility window, move to a real code window first
      -- so NvimTree doesn't vsplit from the wrong place
      local cur_ft = vim.bo[vim.api.nvim_get_current_buf()].filetype
      if skip_ft[cur_ft] then
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local cfg = vim.api.nvim_win_get_config(win)
          local ft  = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
          if cfg.relative == "" and not skip_ft[ft] then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
      end
      api.tree.toggle({ focus = false, find_file = false })
    end, { desc = "Toggle file explorer" })
    keymap.set("n", "<leader>ee", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" }) -- toggle file explorer on current file
    keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" })                     -- collapse file explorer
    keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })                       -- refresh file explorer

    -- TODO: review because it was great until it broke everyting on the `vim.api.nvim_cmd({ cmd = 'qall' }, {})` call
    -- Make :bd and :q behave as usual when tree is visible
    -- vim.api.nvim_create_autocmd({ 'BufEnter', 'QuitPre' }, {
    -- --   nested = false,
    -- --   callback = function(e)
    -- --     local tree = require('nvim-tree.api').tree
    --
    -- --     -- Nothing to do if tree is not opened
    -- --     if not tree.is_visible() then
    -- --       return
    -- --     end
    --
    -- --     -- How many focusable windows do we have? (excluding e.g. incline status window)
    -- --     local winCount = 0
    -- --     for _, winId in ipairs(vim.api.nvim_list_wins()) do
    -- --       if vim.api.nvim_win_get_config(winId).focusable then
    -- --         winCount = winCount + 1
    -- --       end
    -- --     end
    --
    -- --     -- We want to quit and only one window besides tree is left
    -- --     if e.event == 'QuitPre' and winCount == 2 then
    -- --       vim.api.nvim_cmd({ cmd = 'qall' }, {})
    -- --     end
    --
    -- --     -- :bd was probably issued an only tree window is left
    -- --     -- Behave as if tree was closed (see `:h :bd`)
    -- --     if e.event == 'BufEnter' and winCount == 1 then
    -- --       -- Required to avoid "Vim:E444: Cannot close last window"
    -- --       vim.defer_fn(function()
    -- --         -- close nvim-tree: will go to the last buffer used before closing
    -- --         tree.toggle({ find_file = true, focus = true })
    -- --         -- re-open nivm-tree
    -- --         tree.toggle({ find_file = true, focus = false })
    -- --       end, 10)
    -- --     end
    -- --   end
    -- -- })
  end
}
