local opt = vim.opt -- for conciseness

-- line numbers
-- opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
opt.smartindent = true -- copy indent from current line when starting new one

-- line wrapping
-- opt.wrap = false -- disable line wrapping

-- swap files and backup 
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- search settings
-- vim.opt.hlsearch = false
vim.opt.incsearch = true
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift
opt.scrolloff = 8 -- make sure we have 8 lines above and below
opt.isfname:append("@-@")

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- consider hello-world a single word
-- opt.iskeyword.append('-')

vim.opt.updatetime = 250
vim.opt.colorcolumn = "80"

-- clipboard -> still have <leader>y remap but not sure i like it
opt.clipboard:append("unnamedplus") -- use system clipboard as default register