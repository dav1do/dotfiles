local opt = vim.opt

-- vim.g.autoformat = true

opt.grepprg = "rg --vimgrep"

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true         -- shows absolute line number on cursor line (when relative number is on)
opt.ruler = false
opt.cursorline = true

-- tabs & indentation
opt.tabstop = 2        -- tab = N spaces
opt.shiftround = true  -- Round indent
opt.shiftwidth = 2     -- Size of an indent
opt.expandtab = true   -- spaces over tabs
opt.smartindent = true -- Insert indents automatically

-- line wrapping
opt.wrap = false     -- disable line wrapping
opt.splitkeep = "screen" -- default "cursor", trying to play nice with bufferline

-- opt.shortmess:append({ W = true, I = true, c = true, C = true }) -- suppress some messages

-- swap files and backup
opt.swapfile = false
opt.backup = false
opt.undodir = vim.fn.stdpath("data") .. "/undodir"
opt.undofile = true

-- search settings
opt.hlsearch = true
opt.incsearch = true
opt.inccommand = "nosplit" -- preview incremental substitute
opt.ignorecase = true      -- ignore case when searching
opt.smartcase = true       -- if you include mixed case in your search, assumes you want case-sensitive

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes"  -- show sign column so that text doesn't shift
opt.scrolloff = 8       -- keep context visible above/below cursor
opt.sidescrolloff = 8   -- Columns of context
-- opt.isfname:append("@-@")

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- consider hello-world a single word
-- opt.iskeyword.append('-')

opt.updatetime = 250
opt.colorcolumn = "100"

opt.clipboard:append("unnamedplus") -- use system clipboard as default register

opt.showmode = false -- Dont show mode since we have a statusline
opt.fillchars = {
  foldopen = "▾",
  foldclose = "▸",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.smoothscroll = true
-- opt.foldmethod = "expr"
-- opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- -- opt.foldexpr = "v:lua.require'dav1do.util'.foldexpr()"
-- opt.foldlevel = 99
-- opt.foldlevelstart = 3
-- opt.foldtext = "" -- sytanx highlight first line

opt.winminwidth = 5   -- Minimum window width
opt.equalalways = false -- Don't resize all windows when splits open/close
