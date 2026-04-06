-- Custom git utilities (no plugin dependency — pure Neovim API + shell)

-- Git status sidebar: changed-files list, no diff
-- R = refresh  |  <CR> = open file under cursor  |  q = close
local _gs_win, _gs_buf

local _skip_ft = { NvimTree = true, trouble = true, qf = true, dbui = true, dbout = true, OverseerList = true }

local function _gs_find_code_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    local ft  = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if cfg.relative == "" and not _skip_ft[ft] and win ~= _gs_win then
      return win
    end
  end
end

local function _gs_populate()
  local lines = vim.fn.systemlist("git status --short 2>/dev/null")
  if #lines == 0 then lines = { "(no changes)" } end
  vim.bo[_gs_buf].modifiable = true
  vim.api.nvim_buf_set_lines(_gs_buf, 0, -1, false, lines)
  vim.bo[_gs_buf].modifiable = false
end

local function toggle_git_status_sidebar()
  if _gs_win and vim.api.nvim_win_is_valid(_gs_win) then
    vim.api.nvim_win_close(_gs_win, true)
    _gs_win = nil
    return
  end

  if not _gs_buf or not vim.api.nvim_buf_is_valid(_gs_buf) then
    -- scratch=true sets buftype=nofile, bufhidden=hide, swapfile=false
    _gs_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[_gs_buf].modeline = false

    local function map(k, fn, desc)
      vim.keymap.set("n", k, fn, { buffer = _gs_buf, nowait = true, desc = desc })
    end
    map("R", _gs_populate, "Refresh")
    map("q", function()
      if _gs_win and vim.api.nvim_win_is_valid(_gs_win) then
        vim.api.nvim_win_close(_gs_win, true)
        _gs_win = nil
      end
    end, "Close")
    map("<CR>", function()
      local line = vim.api.nvim_get_current_line()
      -- format: "XY filename" or "XY old -> new" (renames)
      local raw = vim.trim(line:sub(4))
      local filename = raw:match("^.+ %-> (.+)$") or raw
      if filename == "" or filename == "(no changes)" then return end
      local target = _gs_find_code_win()
      if target then vim.api.nvim_set_current_win(target) end
      vim.cmd("edit " .. vim.fn.fnameescape(filename))
    end, "Open file")
  end

  _gs_populate()
  -- set width atomically at split time to avoid a reflow
  vim.cmd("botright 45vsplit")
  _gs_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(_gs_win, _gs_buf)
  vim.wo[_gs_win].winfixwidth    = true
  vim.wo[_gs_win].number         = false
  vim.wo[_gs_win].relativenumber = false
  vim.wo[_gs_win].signcolumn     = "no"
  vim.wo[_gs_win].wrap           = false
end

vim.keymap.set("n", "<leader>tS", toggle_git_status_sidebar, { desc = "Git status sidebar" })

-- Claude Code worktree picker
-- Lists all git worktrees and toggles a claude-code.nvim instance for the selected one.
local function claude_worktree_picker()
  local lines = vim.fn.systemlist("git worktree list 2>/dev/null")
  if vim.v.shell_error ~= 0 or #lines == 0 then
    vim.notify("No git worktrees found", vim.log.levels.WARN, { title = "Worktrees" })
    return
  end

  -- Each line: "/abs/path  <hash>  [branch]"
  local items = {}
  for _, line in ipairs(lines) do
    local path, branch = line:match("^(%S+)%s+%S+%s+%[(.-)%]")
    if path then
      table.insert(items, { path = path, branch = branch or "?", display = branch .. "  " .. path })
    end
  end

  if #items == 0 then
    vim.notify("Could not parse worktree list", vim.log.levels.WARN, { title = "Worktrees" })
    return
  end

  vim.ui.select(items, {
    prompt = "Claude session in worktree",
    format_item = function(item) return item.display end,
  }, function(choice)
    if not choice then return end
    -- Temporarily cd to the worktree so claude-code.nvim keys its instance to that git root
    local saved = vim.fn.getcwd()
    vim.fn.chdir(choice.path)
    require("claude-code").toggle()
    vim.fn.chdir(saved)
  end)
end

vim.keymap.set("n", "<leader>cw", claude_worktree_picker, { desc = "Claude in worktree" })
