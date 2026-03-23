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
      { "<leader>p",  group = "find",                                mode = "n" },
      { "<leader>pf", desc = "Find files (hidden)" },
      { "<leader>ff", desc = "Find files" },
      { "<leader>pff",desc = "Find files (all, no ignore)" },
      { "<leader>pr", desc = "Recent files" },
      { "<leader>ps", desc = "Live grep" },
      { "<leader>pss",desc = "Live grep with args" },
      { "<leader>pb", desc = "Open buffers" },
      { "<leader>ph", desc = "Help tags" },
      { "<leader>pq", desc = "Quickfix list" },

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
      { "<leader>bd", desc = "Delete buffer" },
      { "<leader>bx", desc = "Close split" },

      -- ── File explorer ─────────────────────────────────────────────────────
      { "<leader>e",  group = "explorer" },
      { "<leader>ee", desc = "Toggle on current file" },
      { "<leader>ec", desc = "Collapse" },
      { "<leader>er", desc = "Refresh" },

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
      { "<leader>sr", desc = "Search and replace (grug-far)", mode = { "n", "v" } },
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

      -- ── Code (LSP + Rust + Claude) — rust subgroup defined in rust.lua ────
      -- note: <leader>cc/cC/cV registered by claude-code.nvim, not duplicated here
      { "<leader>c",  group = "code",   mode = { "n", "v" } },
      { "<leader>ca", desc = "Code action" },
      { "<leader>cf", desc = "Format code", mode = { "n", "v" } },
      { "<leader>cn", desc = "Navbuddy" },
      { "<leader>cA", desc = "Rust code action" },

      -- ── Trouble panels + terminals ────────────────────────────────────────
      { "<leader>t",  group = "trouble / terminal" },
      { "<leader>td", desc = "Diagnostics" },
      { "<leader>tb", desc = "Buffer diagnostics" },
      { "<leader>ts", desc = "Symbols panel" },
      { "<leader>tl", desc = "LSP definitions / references" },
      { "<leader>to", desc = "TODOs" },
      { "<leader>tf", desc = "FIXMEs / bugs / hacks" },
      { "<leader>tt", desc = "New terminal (vsplit)" },
      { "<leader>tq", desc = "Open psql terminal" },

      -- ── Tests (neotest + RustLsp) ─────────────────────────────────────────
      { "<leader>T",  group = "test" },
      { "<leader>Tr", desc = "Run nearest" },
      { "<leader>Tf", desc = "Run file / module" },
      { "<leader>Tl", desc = "Run last" },
      { "<leader>Tt", desc = "Rust testables picker" },
      { "<leader>Ts", desc = "Toggle summary panel" },
      { "<leader>To", desc = "Open output float" },
      { "<leader>TO", desc = "Toggle output panel (streaming)" },
      { "<leader>Tx", desc = "Stop" },
      { "<leader>Td", desc = "Debug nearest" },

      -- ── Debug (DAP) ───────────────────────────────────────────────────────
      -- note: <leader>d group is registered by nvim-dap; only list extra entries
      { "<leader>du",  desc = "DAP UI open" },
      { "<leader>dut", desc = "DAP UI toggle" },
      { "<leader>de",  desc = "Eval expression", mode = { "n", "v" } },

      -- ── Overseer (build / task runner) — keys defined in overseer.lua ─────
      { "<leader>o",  group = "overseer" },

      -- ── Git / GitHub ──────────────────────────────────────────────────────
      { "<leader>l",  group = "git / github" },
      -- gitsigns
      { "<leader>lb", desc = "Toggle line blame" },
      { "<leader>lB", desc = "Blame line (full)" },
      { "<leader>ls", desc = "Stage hunk",             mode = { "n", "v" } },
      { "<leader>lu", desc = "Undo stage hunk" },
      { "<leader>lr", desc = "Reset hunk" },
      { "<leader>lv", desc = "Preview hunk" },
      -- lazygit / diffview / gitbrowse
      { "<leader>lg", desc = "Lazygit" },
      { "<leader>lo", desc = "Open in browser (GitHub)", mode = { "n", "v" } },
      { "<leader>ld", desc = "Diff view (changes)" },
      { "<leader>lx", desc = "Close diff view" },
      { "<leader>lh", desc = "File history" },
      { "<leader>lH", desc = "Repo history" },
      -- octo (GitHub PRs / issues)
      { "<leader>lp", desc = "PR list" },
      { "<leader>li", desc = "Issue list" },

      -- ── Markdown ──────────────────────────────────────────────────────────
      { "<leader>M",  group = "markdown" },
      { "<leader>Mr", desc = "Toggle render" },

      -- ── Database ──────────────────────────────────────────────────────────
      { "<leader>B",  desc = "Database UI (dadbod)" },

      -- ── Undo / notifications ──────────────────────────────────────────────
      { "<leader>u",  group = "undo / notify" },
      { "<leader>uu", desc = "Toggle undotree" },
      { "<leader>un", desc = "Dismiss all notifications" },
      { "<leader>uw", desc = "Toggle wrap" },

      -- ── Noice messages ────────────────────────────────────────────────────
      -- note: <leader>nh (clear highlights) also appears here due to shared prefix
      { "<leader>n",   group = "noice" },
      { "<leader>nh",  desc = "Clear search highlights" },
      { "<leader>nsl", desc = "Last message" },
      { "<leader>nsh", desc = "Message history" },

      -- ── Vim / config ──────────────────────────────────────────────────────
      { "<leader>v",   group = "vim / config" },
      { "<leader>vpp", desc = "Edit config" },
      { "<leader>vr",  desc = "Reload current file" },

      -- ── Macros ────────────────────────────────────────────────────────────
      -- record: q{letter} → do stuff → q to stop   (use qm, not qa/qb — easy to fat-finger)
      -- play:   @{letter} → run once   |   Q → replay last   |   5@{letter} → run N times
      -- stuck?  q to stop recording, u to undo
      { "@",   group = "play macro" },
      { "@@",  desc = "Repeat last macro" },
      { "Q",   desc = "Replay last macro" },

      -- ── Clipboard ─────────────────────────────────────────────────────────
      { "<leader>D",  desc = "Delete without copying",           mode = { "n", "v" } },
      { "<leader>P",  desc = "Paste last yank (safe, ignores deletes)", mode = { "n", "v" } },
      { "<leader>ra", desc = "Replace word under cursor in file" },

      -- ── Text objects (operator-pending + visual) ─────────────────────
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
        -- treesitter (nvim-treesitter-textobjects)
        { "if",  desc = "function (inner)" },  { "af",  desc = "function (outer)" },
        { "ic",  desc = "class/impl (inner)" },{ "ac",  desc = "class/impl (outer)" },
        { "ia",  desc = "argument (inner)" },  { "aa",  desc = "argument (outer)" },
        { "ib",  desc = "block (inner)" },     { "ab",  desc = "block (outer)" },
      },

      -- ── goto (LSP) + surround (mini.surround) ────────────────────────────
      {
        mode = { "n", "v" },
        { "g",   group = "goto" },
        { "gd",  desc = "Definition" },
        { "gD",  desc = "Declaration" },
        { "gi",  desc = "Implementation" },
        { "go",  desc = "Type definition" },
        -- gr removed: Neovim 0.11+ uses gr* prefix (grr/grn/gra/gri/grt/grx)
        { "gR",  desc = "References — panel (Trouble)" },
        { "gS",  desc = "Signature help" },
        { "<F2>", desc = "Rename symbol" },
        { "gs",  group = "surround" },
        { "gsa", desc = "Add surrounding" },
        { "gsd", desc = "Delete surrounding" },
        { "gsr", desc = "Replace surrounding" },
        { "gsf", desc = "Find surrounding →" },
        { "gsF", desc = "Find surrounding ←" },
        { "gsh", desc = "Highlight surrounding" },
        { "gsn", desc = "Update n_lines" },
        { "z",   group = "fold" },
      },

      -- ── [ ] navigation ────────────────────────────────────────────────────
      {
        mode = { "n", "v" },
        { "]",   group = "next" },
        { "]c",  desc = "Next hunk" },
        { "]e",  desc = "Next error" },
        { "]E",  desc = "Next error (project-wide)" },
        { "]d",  desc = "Next diagnostic" },
        { "]w",  desc = "Next word reference" },
        { "]f",  desc = "Next function start" },
        { "]F",  desc = "Next function end" },
        { "]i",  desc = "Next impl/class start" },
        { "]I",  desc = "Next impl/class end" },
        { "]a",  desc = "Next argument" },
        { "]t",  desc = "Next todo" },
        { "[",   group = "prev" },
        { "[c",  desc = "Prev hunk" },
        { "[e",  desc = "Prev error" },
        { "[E",  desc = "Prev error (project-wide)" },
        { "[d",  desc = "Prev diagnostic" },
        { "[w",  desc = "Prev word reference" },
        { "[f",  desc = "Prev function start" },
        { "[F",  desc = "Prev function end" },
        { "[i",  desc = "Prev impl/class start" },
        { "[I",  desc = "Prev impl/class end" },
        { "[a",  desc = "Prev argument" },
        { "[t",  desc = "Prev todo" },
      },
    })
  end,
}
