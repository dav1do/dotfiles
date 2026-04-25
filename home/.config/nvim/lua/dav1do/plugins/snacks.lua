return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  config = function(_, opts)
    require("snacks").setup(opts)
    -- Flip the explorer confirm prompt so Enter = Yes.
    -- Default order is { "No", "Yes" }, which selects "No" on open.
    local picker_util = require("snacks.picker.util")
    picker_util.confirm = function(prompt, fn)
      Snacks.picker.select({ "Yes", "No" }, {
        prompt = prompt,
        snacks = { layout = { layout = { max_width = 60 } } },
      }, function(_, idx)
        if idx == 1 then
          fn()
        end
      end)
    end
  end,
  opts = {
    -- disabled — already handled by existing plugins
    bigfile = { enabled = true, size = 1000 * 1024 },
    dashboard = { enabled = false },
    explorer = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = false },
    picker = {
      enabled = true,
      sources = {
        explorer = {
          win = {
            list = {
              keys = {
                ["<c-p>"] = function(picker)
                  -- Focus a real code window before opening the files picker,
                  -- otherwise the picker may create an empty buffer in the explorer.
                  local switched = false
                  if picker.main and vim.api.nvim_win_is_valid(picker.main) then
                    vim.api.nvim_set_current_win(picker.main)
                    switched = true
                  end
                  if not switched then
                    local skip = { snacks_picker_list = true, snacks_picker_input = true }
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                      local cfg = vim.api.nvim_win_get_config(win)
                      local bt = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
                      if cfg.relative == "" and not skip[bt] then
                        vim.api.nvim_set_current_win(win)
                        break
                      end
                    end
                  end
                  Snacks.picker.files()
                end,
                -- Force tmux navigation from explorer (vim-tmux-navigator can't
                -- detect the edge when the explorer is the leftmost split)
                ["<c-h>"] = function()
                  vim.fn.system("tmux select-pane -L")
                end,
                -- disable alt/meta keys (terminal doesn't send meta correctly)
                ["<a-d>"] = false,
                ["<a-f>"] = false,
                ["<a-h>"] = false,
                ["<a-i>"] = false,
                ["<a-m>"] = false,
                ["<a-p>"] = false,
                ["<a-w>"] = false,
                ["<a-r>"] = false,
              },
            },
          },
        },
      },
    },
    quickfile = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    terminal = { enabled = false },
    zen = { enabled = false },

    -- enabled
    gh = { enabled = true },
    gitbrowse = { enabled = true },
    rename = { enabled = true },
    bufdelete = { enabled = true },
    animate = { enabled = false }, -- animations cause lag on every cursor move
    words = { enabled = true },
    indent = {
      enabled = true,
      indent = { char = "│" },
      scope = { enabled = true, char = "│" },
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
    { "<leader>bD", function()
      local buf  = vim.api.nvim_get_current_buf()
      -- non-floating windows open right now
      local real_wins = vim.tbl_filter(function(w)
        return vim.api.nvim_win_get_config(w).relative == ""
      end, vim.api.nvim_list_wins())
      -- windows currently showing this specific buffer
      local buf_wins = vim.fn.win_findbuf(buf)

      if #real_wins > 1 then
        -- in a split: close the window
        vim.cmd("close")
        -- if no other window was showing this buffer, clean it up too
        if #buf_wins == 1 and vim.api.nvim_buf_is_valid(buf) then
          Snacks.bufdelete({ buf = buf, force = vim.bo[buf].buftype ~= "" })
        end
      else
        -- only window: just delete buffer, snacks picks an alternate
        Snacks.bufdelete({ force = vim.bo.buftype ~= "" })
      end
    end, desc = "Close window + delete buffer" },
    { "<leader>bo", function() Snacks.bufdelete.other() end, desc = "Delete other buffers" },
    { "<leader>lp", function() Snacks.gh.pr() end,     desc = "PR list" },
    { "<leader>li", function() Snacks.gh.issue() end,  desc = "Issue list" },
    { "<leader>ee", function() Snacks.explorer() end, desc = "Toggle file explorer" },
    { "]w",         function() Snacks.words.jump(1, true) end,  desc = "Next word reference" },
    { "[w",         function() Snacks.words.jump(-1, true) end, desc = "Prev word reference" },
  },
}
