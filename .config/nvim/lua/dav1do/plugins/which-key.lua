return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    plugins = { spelling = true },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    wk.add({

      -- ── Finding & navigation ──────────────────────────────────────────────
      { "<leader>p",   group = "find",                  mode = "n" },
      { "<leader>pf",  desc = "Find files (hidden)" },
      { "<leader>ff",  desc = "Find files" },
      { "<leader>pff", desc = "Find files (all, no ignore)" },
      { "<leader>pr",  desc = "Recent files" },
      { "<leader>ps",  desc = "Live grep" },
      { "<leader>pss", desc = "Live grep with args" },
      { "<leader>pb",  desc = "Open buffers" },
      { "<leader>ph",  desc = "Help tags" },
      { "<leader>pk",  desc = "Search keymaps" },
      { "<leader>pp",  desc = "Resume last picker" },
      { "<leader>pg",  desc = "Changed files (git status)" },
      { "<leader>pq",  desc = "Quickfix list" },
      { "<leader>pn",  desc = "[navbuddy] Code structure" },

      -- ── Buffers ───────────────────────────────────────────────────────────
      -- navigate: <C-^> last file, <leader>pb fuzzy picker, <C-o>/<C-i> jump list
      {
        "<leader>b",
        group = "buffers",
        expand = function()
          return require("which-key.extras").expand.buf()
        end
      },
      { "<leader>bf", desc = "Find buffers" },
      { "<leader>bd", desc = "[snacks] Delete buffer (keep split)" },
      { "<leader>bx", desc = "Close split (keep buffer)" },
      { "<leader>bq", desc = "[snacks] Close window + delete buffer" },

      -- ── File explorer ─────────────────────────────────────────────────────
      { "<leader>e",  group = "explorer" },
      { "<leader>ee", desc = "[nvim-tree] Toggle on current file" },
      { "<leader>ec", desc = "[nvim-tree] Collapse" },
      { "<leader>er", desc = "[nvim-tree] Refresh" },

      -- ── File ──────────────────────────────────────────────────────────────
      { "<leader>f",  group = "file" },
      { "<leader>fn", "<cmd>enew<cr>", desc = "New file" },
      { "<leader>fs", desc = "Scratch buffer" },
      { "<leader>ft", desc = "Set filetype" },

      -- ── Splits / windows / replace ────────────────────────────────────────
      { "<leader>s",  group = "splits + replace" },
      { "<leader>sv", desc = "Split vertical" },
      { "<leader>sh", desc = "Split horizontal" },
      { "<leader>se", desc = "Equalize splits" },
      { "<leader>sx", desc = "Close split" },
      { "<leader>sm", desc = "Maximize / restore split" },
      { "<leader>sr", desc = "[grug-far] Search and replace", mode = { "n", "v" } },
      { "<leader>W",  proxy = "<c-w>", group = "window commands" },
      { "<leader>m",  group = "move window" },
      { "<leader>mh", desc = "Move window left" },
      { "<leader>mj", desc = "Move window down" },
      { "<leader>mk", desc = "Move window up" },
      { "<leader>ml", desc = "Move window right" },

      -- ── Write / quit ──────────────────────────────────────────────────────
      { "<leader>w",   group = "write" },
      { "<leader>ww",  desc = "Write file" },
      { "<leader>q",   group = "quit" },
      { "<leader>qa",  desc = "Quit all" },
      { "<leader>qqa", desc = "Force quit all" },

      -- ── Code (LSP + conform + claude + rust) ─────────────────────────────
      -- crates/cargo: <localleader>v/f/d/u/U/D/r in Cargo.toml (buffer-local)
      -- navbuddy: <leader>pn
      { "<leader>c",  group = "code",   mode = { "n", "v" } },
      { "<leader>ca", desc = "[lsp] Code action (rust-aware)" },
      { "<leader>ce", desc = "[rust] Next diagnostic (cargo-style, cycle)" },
      { "<leader>cE", desc = "[rust] Explain error code" },
      { "<leader>cf", desc = "[conform] Format",             mode = { "n", "v" } },
      { "<leader>cc", desc = "[claude] Toggle" },
      { "<leader>cC", desc = "[claude] Continue last session" },
      { "<leader>cV", desc = "[claude] Verbose mode" },

      -- ── Trouble panels + terminals ────────────────────────────────────────
      { "<leader>t",  group = "trouble / terminal" },
      { "<leader>td", desc = "[trouble] Diagnostics (project)" },
      { "<leader>tb", desc = "[trouble] Buffer diagnostics" },
      { "<leader>ts", desc = "[trouble] Symbols sidebar" },
      { "<leader>tl", desc = "[trouble] LSP definitions / references" },
      { "<leader>to", desc = "[trouble] TODOs" },
      { "<leader>tf", desc = "[trouble] FIXMEs / bugs / hacks" },
      { "<leader>tq", desc = "[term] psql terminal" },

      -- ── Tests (neotest + RustLsp) ─────────────────────────────────────────
      { "<leader>T",  group = "test" },
      { "<leader>Tr", desc = "[neotest] Run nearest" },
      { "<leader>Tf", desc = "[neotest] Run file / module" },
      { "<leader>Tl", desc = "[neotest] Run last" },
      { "<leader>Tt", desc = "[rust] Testables picker" },
      { "<leader>Ts", desc = "[neotest] Toggle summary panel" },
      { "<leader>To", desc = "[neotest] Output float" },
      { "<leader>TO", desc = "[neotest] Toggle output panel (streaming)" },
      { "<leader>Tx", desc = "[neotest] Stop" },
      { "<leader>Td", desc = "[neotest] Debug nearest" },

      -- ── Debug (DAP) ───────────────────────────────────────────────────────
      -- note: <leader>d group is registered by nvim-dap; only list extra entries
      { "<leader>du",  desc = "[dapui] Open" },
      { "<leader>dut", desc = "[dapui] Toggle" },
      { "<leader>de",  desc = "[dapui] Eval expression", mode = { "n", "v" } },

      -- ── Overseer (build / task runner) — keys defined in overseer.lua ─────
      { "<leader>o",  group = "overseer" },

      -- ── Git / GitHub ──────────────────────────────────────────────────────
      { "<leader>l",  group = "git / github" },
      { "<leader>lb", desc = "[gitsigns] Toggle line blame" },
      { "<leader>lB", desc = "[gitsigns] Blame line (full)" },
      { "<leader>ls", desc = "[gitsigns] Stage hunk",        mode = { "n", "v" } },
      { "<leader>lu", desc = "[gitsigns] Undo stage hunk" },
      { "<leader>lr", desc = "[gitsigns] Reset hunk" },
      { "<leader>lv", desc = "[gitsigns] Preview hunk" },
      { "<leader>lg", desc = "[lazygit] Open" },
      { "<leader>ld", desc = "[diffview] Open changes" },
      { "<leader>lx", desc = "[diffview] Close" },
      { "<leader>lh", desc = "[diffview] File history" },
      { "<leader>lH", desc = "[diffview] Repo history" },
      { "<leader>lo", desc = "[gitbrowse] Open in browser",  mode = { "n", "v" } },
      -- review flow: lR → pick file → ]c/[c hunks → :Octo review submit
      { "<leader>lp", desc = "[octo] PR list" },
      { "<leader>li", desc = "[octo] Issue list" },
      { "<leader>ln", desc = "[octo] Notifications" },
      { "<leader>lf", desc = "[octo] Search GitHub" },
      { "<leader>lR", desc = "[octo] Review files (start)" },

      -- ── Markdown ──────────────────────────────────────────────────────────
      { "<leader>M",  group = "markdown" },
      { "<leader>Mr", desc = "[render-markdown] Toggle" },

      -- ── Database ──────────────────────────────────────────────────────────
      { "<leader>B",  desc = "[dadbod] Database UI" },

      -- ── Undo / notifications ──────────────────────────────────────────────
      { "<leader>u",  group = "undo / notify" },
      { "<leader>uu", desc = "[undotree] Toggle" },
      { "<leader>un", desc = "[noice] Dismiss all notifications" },
      { "<leader>uw", desc = "Toggle wrap" },

      -- ── Noice messages ────────────────────────────────────────────────────
      -- note: <leader>nh (clear highlights) shares this prefix by coincidence
      { "<leader>n",   group = "noice" },
      { "<leader>nh",  desc = "Clear search highlights" },
      { "<leader>nsl", desc = "[noice] Last message" },
      { "<leader>nsh", desc = "[noice] Message history" },

      -- ── Vim / config ──────────────────────────────────────────────────────
      { "<leader>v",   group = "vim / config" },
      { "<leader>vpp", desc = "Edit config" },
      { "<leader>vr",  desc = "Reload current file" },

      -- ── Macros ────────────────────────────────────────────────────────────
      -- record: gq{letter} → do stuff → gq to stop
      -- play:   @{letter} → run once   |   Q / @@ → replay last   |   5@{letter} → run N times
      -- q is disabled globally (panels override it with buffer-local close mappings)
      { "gq",  desc = "Record macro (gq{register})" },
      { "@",   group = "play macro" },
      { "@@",  desc = "Repeat last macro" },
      { "Q",   desc = "Replay last macro" },

      -- ── Clipboard ─────────────────────────────────────────────────────────
      { "<leader>D",  desc = "Delete without copying",                mode = { "n", "v" } },
      { "<leader>P",  desc = "Paste last yank (safe, ignores deletes)", mode = { "n", "v" } },
      { "<leader>ra", desc = "Replace word under cursor in file" },

      -- ── Text objects (operator-pending + visual) ──────────────────────────
      {
        mode = { "o", "x" },
        -- built-in
        { "i",   group = "inner" },
        { "a",   group = "around" },
        { "iw",  desc = "word" },          { "aw",  desc = "word + space" },
        { "iW",  desc = "WORD" },          { "aW",  desc = "WORD + space" },
        { "ip",  desc = "paragraph" },     { "ap",  desc = "paragraph + blank" },
        { 'i"',  desc = "double quotes" }, { 'a"',  desc = "double quotes + surround" },
        { "i'",  desc = "single quotes" }, { "a'",  desc = "single quotes + surround" },
        { "i`",  desc = "backticks" },     { "a`",  desc = "backticks + surround" },
        { "i(",  desc = "parens" },        { "a(",  desc = "parens + surround" },
        { "i{",  desc = "braces" },        { "a{",  desc = "braces + surround" },
        { "i[",  desc = "brackets" },      { "a[",  desc = "brackets + surround" },
        { "it",  desc = "tag" },           { "at",  desc = "tag + surround" },
        -- nvim-treesitter-textobjects
        { "if",  desc = "[treesitter] function (inner)" },  { "af",  desc = "[treesitter] function (outer)" },
        { "ic",  desc = "[treesitter] class/impl (inner)" },{ "ac",  desc = "[treesitter] class/impl (outer)" },
        { "ia",  desc = "[treesitter] argument (inner)" },  { "aa",  desc = "[treesitter] argument (outer)" },
        { "ib",  desc = "[treesitter] block (inner)" },     { "ab",  desc = "[treesitter] block (outer)" },
      },

      -- ── goto (LSP) + surround (mini.surround) ────────────────────────────
      {
        mode = { "n", "v" },
        { "g",    group = "goto" },
        { "gd",   desc = "[lsp] Definition" },
        { "gD",   desc = "[lsp] Declaration" },
        { "gi",   desc = "[lsp] Implementation" },
        { "go",   desc = "[lsp] Type definition" },
        -- gr removed: Neovim 0.11+ uses gr* prefix (grr/grn/gra/gri/grt/grx)
        { "gR",   desc = "[trouble] References panel" },
        { "gS",   desc = "[lsp] Signature help" },
        { "<F2>", desc = "[lsp] Rename symbol" },
        { "gs",   group = "surround" },
        { "gsa",  desc = "[mini] Add surrounding" },
        { "gsd",  desc = "[mini] Delete surrounding" },
        { "gsr",  desc = "[mini] Replace surrounding" },
        { "gsf",  desc = "[mini] Find surrounding →" },
        { "gsF",  desc = "[mini] Find surrounding ←" },
        { "gsh",  desc = "[mini] Highlight surrounding" },
        { "gsn",  desc = "[mini] Update n_lines" },
        { "z",    group = "fold" },
      },

      -- ── [ ] navigation ────────────────────────────────────────────────────
      {
        mode = { "n", "v" },
        { "]",   group = "next" },
        { "]c",  desc = "[gitsigns] Next hunk" },
        { "]e",  desc = "Next error" },
        { "]E",  desc = "[trouble] Next error (project-wide)" },
        { "]d",  desc = "Next diagnostic" },
        { "]w",  desc = "[snacks] Next word reference" },
        { "]f",  desc = "[treesitter] Next function start" },
        { "]F",  desc = "[treesitter] Next function end" },
        { "]i",  desc = "[treesitter] Next impl/class start" },
        { "]I",  desc = "[treesitter] Next impl/class end" },
        { "]a",  desc = "[treesitter] Next argument" },
        { "]t",  desc = "[todo-comments] Next todo" },
        { "]q",  desc = "Next quickfix item" },
        { "[",   group = "prev" },
        { "[c",  desc = "[gitsigns] Prev hunk" },
        { "[e",  desc = "Prev error" },
        { "[E",  desc = "[trouble] Prev error (project-wide)" },
        { "[d",  desc = "Prev diagnostic" },
        { "[w",  desc = "[snacks] Prev word reference" },
        { "[f",  desc = "[treesitter] Prev function start" },
        { "[F",  desc = "[treesitter] Prev function end" },
        { "[i",  desc = "[treesitter] Prev impl/class start" },
        { "[I",  desc = "[treesitter] Prev impl/class end" },
        { "[a",  desc = "[treesitter] Prev argument" },
        { "[t",  desc = "[todo-comments] Prev todo" },
        { "[q",  desc = "Prev quickfix item" },
      },
    })
  end,
}
