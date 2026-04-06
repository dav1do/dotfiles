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
        local function map(key, action, desc)
          vim.keymap.set("n", key, action, { buffer = bufnr, nowait = true, desc = desc })
        end

        -- apply all default nvim-tree keymaps first
        api.config.mappings.default_on_attach(bufnr)

        -- q closes tree (consistent with all other tool panels)
        map("q", api.tree.close, "Close tree")
        -- ? shows tree help (newer nvim-tree moved this to g?, so re-bind explicitly)
        map("?", api.tree.toggle_help, "Help")
        -- remove nvim-tree's s (system open) so Flash jump works inside the tree
        pcall(vim.keymap.del, "n", "s", { buffer = bufnr })

        -- n = new file/dir (alias for a; more intuitive than "add")
        map("n", api.fs.create, "New file/dir")

        -- gs = show git-changed files via telescope picker, then reveal in tree
        -- (bridges <leader>ps workflow into the tree; uses telescope-ui-select)
        map("gs", function()
          local changed = vim.fn.systemlist("git diff --name-only HEAD 2>/dev/null")
          local untracked = vim.fn.systemlist("git ls-files --others --exclude-standard 2>/dev/null")
          for _, f in ipairs(untracked) do table.insert(changed, f) end
          if #changed == 0 then
            vim.notify("No changed files", vim.log.levels.INFO, { title = "nvim-tree" })
            return
          end
          vim.ui.select(changed, { prompt = "Git changed files" }, function(choice)
            if choice then
              api.tree.find_file({ buf = vim.fn.fnamemodify(choice, ":p"), open = true, focus = true })
            end
          end)
        end, "Git changed: find in tree")

        -- Key file-op reference (all defaults, listed here for which-key visibility):
        --   r  = rename / move (edit the full path to move across dirs — this is your `mv`)
        --   c  = copy (mark), x = cut (mark), p = paste at current dir — this is your `cp`
        --   d  = delete
        --   y / Y / gy = copy name / relative path / absolute path
        --   f / F = live filter / clear filter
        --   H  = toggle hidden/dotfiles
        --   I  = toggle git-ignored files
        --   W / E = collapse all / expand all
        --   m  = bookmark node (bmv = move bookmarked)
        --   -  = navigate up to parent dir
        --   <Tab> = preview without opening
        --   <C-v> / <C-x> / <C-t> = open in vsplit / hsplit / tab
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
    keymap.set("n", "<leader>ee", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" })
    keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>",        { desc = "Collapse file explorer" })
    keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>",         { desc = "Refresh file explorer" })
    -- git-changed: pick from changed files → reveal in tree (<leader>ps equivalent for the explorer)
    keymap.set("n", "<leader>eg", function()
      local changed = vim.fn.systemlist("git diff --name-only HEAD 2>/dev/null")
      local untracked = vim.fn.systemlist("git ls-files --others --exclude-standard 2>/dev/null")
      for _, f in ipairs(untracked) do table.insert(changed, f) end
      if #changed == 0 then
        vim.notify("No changed files", vim.log.levels.INFO, { title = "nvim-tree" })
        return
      end
      local api = require("nvim-tree.api")
      vim.ui.select(changed, { prompt = "Git changed files" }, function(choice)
        if choice then
          api.tree.find_file({ buf = vim.fn.fnamemodify(choice, ":p"), open = true, focus = false })
        end
      end)
    end, { desc = "Explorer: git changed files" })

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
