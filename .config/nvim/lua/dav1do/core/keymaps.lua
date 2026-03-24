-- set leader key to space
vim.g.mapleader = " "
-- <localleader> defaults to \ — used for filetype-specific bindings (e.g. crates in Cargo.toml)

-- vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- General Keymaps -------------------

-- use jk to exit insert mode
vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
vim.keymap.set("i", "kj", "<ESC>", { desc = "Exit insert mode with kj" })
-- clear search highlights
vim.keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- delete single character without copying into register
vim.keymap.set("n", "x", '"_x')

-- increment/decrement numbers
-- vim.keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
-- vim.keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })     -- split window vertically
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })   -- split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })      -- make split windows equal width & height
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window
vim.keymap.set("n", "<leader>bx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

vim.keymap.set("n", "<leader>ml", "<C-w>L", { desc = "Move window to right split" })
vim.keymap.set("n", "<leader>mj", "<C-w>J", { desc = "Move window to bottom split" })
vim.keymap.set("n", "<leader>mk", "<C-w>K", { desc = "Move window to top split" })
vim.keymap.set("n", "<leader>mh", "<C-w>H", { desc = "Move window to left split" })

-- Move to window using the <ctrl> hjkl keys (not necessary with tmux plugin)
-- vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
-- vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
-- vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
-- vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })


-- <Esc> exits terminal mode for plain shell terminals (psql, generic shell).
-- TUI apps that use <Esc> internally are excluded:
--   claude  → uses <C-e> instead (see claude.lua) to avoid cancelling the process
--   lazygit → uses <Esc> for panel navigation; use <C-\><C-n> to escape if needed
local tui_patterns = { "claude", "lazygit" }
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    for _, pat in ipairs(tui_patterns) do
      if name:find(pat) then return end
    end
    vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = args.buf, desc = "Exit terminal mode" })
  end,
})

-- psql in a bottom split, using $DATABASE_URL if set
vim.keymap.set("n", "<leader>tq", function()
  local url = os.getenv("DATABASE_URL")
  local cmd = url and ("psql " .. url) or "psql"
  vim.cmd("botright split | terminal " .. cmd)
  vim.cmd("resize " .. math.floor(vim.o.lines * 0.4))
  vim.cmd("startinsert")
end, { desc = "Open psql terminal" })

-- better up/down with line wrapping
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- map up/down for faster movement (gj/gk to respect line wrapping)
vim.keymap.set({ "n", "v" }, "<Up>", "2gk", { desc = "Up 2 lines" })
vim.keymap.set({ "n", "v" }, "<Down>", "2gj", { desc = "Down 2 lines" })
vim.keymap.set({ "n", "v" }, "<Right>", "2l", { desc = "Right 2" })
vim.keymap.set({ "n", "v" }, "<Left>", "2h", { desc = "Left 2" })

-- Resize window (disabled mission control shortcuts for up/down because mac uses ctrl up to zoom to mgmt view or whatever)
vim.keymap.set("n", "<C-Up>", "<cmd>resize +4<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -4<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -4<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +4<cr>", { desc = "Increase Window Width" })

-- Move Lines
vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
-- allow moving hightlighted text up and down (alt or shift)
vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })
vim.keymap.set("v", "J", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "K", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- buffers: use <leader>pb for fuzzy picker, <C-^> to toggle last two files
-- H/L restored as vim built-ins (top/bottom of visible screen)
-- <leader>bd is handled by snacks.lua (context-aware: dadbod, tool buffers, etc.)
vim.keymap.set("n", "<leader>fs", function()
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.ui.input({ prompt = "Filetype (empty to skip): " }, function(ft)
    if ft and ft ~= "" then
      vim.bo.filetype = ft
    end
  end)
end, { desc = "Scratch buffer" })

vim.keymap.set("n", "<leader>ft", function()
  vim.ui.input({ prompt = "Set filetype: ", default = vim.bo.filetype }, function(ft)
    if ft and ft ~= "" then
      vim.bo.filetype = ft
    end
  end)
end, { desc = "Set filetype" })

-- cursor mgmt
vim.keymap.set("n", "J", "mzJ`z") -- don't move cursor when appending text to line
-- keep cursor centered when paging and searching
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- structural navigation: use ]f/[f (functions) and ]i/[i (impl/class) directly

vim.keymap.set({ "n", "v" }, "<leader>D", [["_d]], { desc = "Delete without copying" })
vim.keymap.set({ "n", "v" }, "<leader>P", [["0p]], { desc = "Paste last yank (safe)" })

-- Macro recording: moved to explicit keys to prevent accidental q-in-code-buffer triggers.
-- Buffer-local q mappings (trouble, neotest, rustaceanvim panels) are unaffected — they
-- always take precedence over this global mapping.
vim.keymap.set("n", "q",  "<nop>")                                        -- disable accidental recording
vim.keymap.set("n", "gq", "q",   { desc = "Record macro (gq{register})" }) -- intentional: gqm starts @m, gq stops
vim.keymap.set("n", "Q",  "@@",  { desc = "Replay last macro" })

-- Notify when recording starts/stops so it's impossible to miss.
-- Capture the register in Enter because reg_recording() is already cleared by Leave.
local _macro_reg = ""
vim.api.nvim_create_autocmd("RecordingEnter", {
  callback = function()
    _macro_reg = vim.fn.reg_recording()
    vim.notify("Recording @" .. _macro_reg .. "   gq to stop", vim.log.levels.WARN, { title = "Macro", timeout = 10000 })
  end,
})
vim.api.nvim_create_autocmd("RecordingLeave", {
  callback = function()
    vim.notify("Saved @" .. _macro_reg .. "   Q or @" .. _macro_reg .. " to play", vim.log.levels.INFO, { title = "Macro", timeout = 10000 })
  end,
})

-- vertical edit mode doesn't save changes unless you press esc (primeagean)
vim.keymap.set("i", "<C-c>", "<Esc>")

-- replace the word under cursor in entire file with whatever you type
vim.keymap.set("n", "<leader>ra", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true }) -- set current file as exectuable

-- keep visual selection when indenting
vim.keymap.set("v", ">", ">gv", { desc = "Indent and keep selection" })
vim.keymap.set("v", "<", "<gv", { desc = "Dedent and keep selection" })

-- toggles
vim.keymap.set("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.wo.linebreak = vim.wo.wrap -- word-boundary breaks when wrap is on
end, { desc = "Toggle wrap" })

-- reload plugins
vim.keymap.set("n", "<leader>vpp", "<cmd>e ~/.config/nvim/lua/dav1do/init.lua<CR>")
vim.keymap.set("n", "<leader>vr", "<cmd>source %<CR>", { desc = "Reload current file" })

-- file mgmt
-- vim.keymap.set("n", "<leader><leader>", function()
--   vim.cmd("so") --reload file
-- end)

vim.keymap.set("n", "<leader>ww", function()
  vim.cmd("w")
end, { desc = "write file" })
vim.keymap.set("n", "<leader>qa", function()
  vim.cmd("qa")
end, { desc = "quit all buffers" })

vim.keymap.set("n", "<leader>qqa", function()
  vim.cmd("qa!")
end, { desc = "force quit all" })

-- quickfix navigation (used with <leader>crq / :copen)
vim.keymap.set("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
vim.keymap.set("n", "[q", "<cmd>cprev<cr>", { desc = "Prev quickfix" })

-- diagnostic/error navigation (current buffer only)
vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end,  { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
vim.keymap.set("n", "]e", function() vim.diagnostic.jump({ count = 1,  severity = vim.diagnostic.severity.ERROR }) end, { desc = "Next error" })
vim.keymap.set("n", "[e", function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end, { desc = "Prev error" })

-- cross-file error navigation via Trouble (jumps through project-wide diagnostics)
-- Ensures the diagnostics list is open (background) so there is data to navigate.
vim.keymap.set("n", "]E", function()
  local t = require("trouble")
  if not t.is_open({ mode = "diagnostics" }) then
    t.open({ mode = "diagnostics", focus = false })
  end
  t.next({ mode = "diagnostics", skip_groups = true, jump = true })
end, { desc = "Next error (project)" })
vim.keymap.set("n", "[E", function()
  local t = require("trouble")
  if not t.is_open({ mode = "diagnostics" }) then
    t.open({ mode = "diagnostics", focus = false })
  end
  t.prev({ mode = "diagnostics", skip_groups = true, jump = true })
end, { desc = "Prev error (project)" })
