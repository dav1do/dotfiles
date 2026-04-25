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

      -- ── Leader groups ──────────────────────────────────────────────────────
      { "<leader>p", group = "pickers", mode = "n" },
      {
        "<leader>b",
        group = "buffers",
        expand = function()
          return require("which-key.extras").expand.buf()
        end,
      },
      { "<leader>e", group = "explorer" },
      { "<leader>f", group = "file" },
      { "<leader>s", group = "splits" },
      { "<leader>W", proxy = "<c-w>", group = "window commands" },
      -- annotate the useful subset of <C-w> commands (proxy sends the actual key)
      { "<leader>WT", desc = "promote split → new tab (<C-w>T)" },
      { "<leader>Wp", desc = "go to previous window (<C-w>p)" },
      { "<leader>Wx", desc = "exchange with next window (<C-w>x)" },
      { "<leader>w", group = "write" },
      { "<leader>c", group = "code", mode = { "n", "v" } },
      { "<leader>t", group = "panels / tabs" },
      { "<leader>T", group = "test" },
      { "<leader>o", group = "ops/run" },
      { "<leader>l", group = "git / github" },
      { "<leader>u", group = "undo / toggles" },
      { "<leader>n", group = "messages" },
      { "<leader>r", group = "replace" },

      -- ── Text objects (o/x) — built-in vim objects have no desc ─────────────
      {
        mode = { "o", "x" },
        { "i", group = "inner" },
        { "a", group = "around" },
        { "iw", desc = "word" },
        { "aw", desc = "word + space" },
        { "iW", desc = "WORD" },
        { "aW", desc = "WORD + space" },
        { "ip", desc = "paragraph" },
        { "ap", desc = "paragraph + blank" },
        { 'i"', desc = "double quotes" },
        { 'a"', desc = "double quotes + surround" },
        { "i'", desc = "single quotes" },
        { "a'", desc = "single quotes + surround" },
        { "i`", desc = "backticks" },
        { "a`", desc = "backticks + surround" },
        { "i(", desc = "parens" },
        { "a(", desc = "parens + surround" },
        { "i{", desc = "braces" },
        { "a{", desc = "braces + surround" },
        { "i[", desc = "brackets" },
        { "a[", desc = "brackets + surround" },
        { "it", desc = "tag" },
        { "at", desc = "tag + surround" },
        { "if", desc = "[treesitter] function (inner)" },
        { "af", desc = "[treesitter] function (outer)" },
        { "ic", desc = "[treesitter] class/impl (inner)" },
        { "ac", desc = "[treesitter] class/impl (outer)" },
        { "ia", desc = "[treesitter] argument (inner)" },
        { "aa", desc = "[treesitter] argument (outer)" },
        { "ib", desc = "[treesitter] block (inner)" },
        { "ab", desc = "[treesitter] block (outer)" },
      },

      -- ── g / ] / [ / @ groups ───────────────────────────────────────────────
      {
        mode = { "n", "v" },
        { "g", group = "goto" },
        { "gs", group = "surround" },
        { "z", group = "fold" },
        { "za", desc = "toggle fold" },
        { "zO", desc = "open fold + nested" },
        { "zc", desc = "close fold" },
        { "zC", desc = "close fold + nested" },
        { "zr", desc = "reveal one level" },
        { "zR", desc = "reveal all" },
        { "zm", desc = "mask one level" },
        { "zM", desc = "mask all" },
        { "zs", desc = "fold to level 2 (standard)" },
        { "]", group = "next" },
        { "[", group = "prev" },
        { "]t", desc = "next tab" },
        { "[t", desc = "prev tab" },
      },
      { "@", group = "play macro" },
    })
  end,
}
