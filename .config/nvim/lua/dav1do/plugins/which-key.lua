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
      { "<leader>f",  group = "file" }, -- group
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File", mode = "n" },
      { "<leader>fb", function() print("hello") end,   desc = "Foobar" },
      { "<leader>fn", desc = "New File" },
      { "<leader>f1", hidden = true },                 -- hide this keymap
      { "<leader>w",  proxy = "<c-w>",                 group = "windows" }, -- proxy to window mappings
      {
        "<leader>b",
        group = "buffers",
        expand = function()
          return require("which-key.extras").expand.buf()
        end
      },
      {
        mode = { "n", "v" },
        { "g",             desc = "+goto" },
        { "gs",            desc = "+surround" },
        { "z",             desc = "+fold" },
        { "]",             desc = "+next" },
        { "[",             desc = "+prev" },
        { "<leader><tab>", desc = "+tabs" },
        { "<leader>b",     desc = "+buffer" },
        { "<leader>c",     desc = "+code" },
        { "<leader>p",     desc = "+file/find" },
        { "<leader>l",     desc = "+git" },
        { "<leader>gh",    desc = "+hunks" },
        { "<leader>q",     desc = "+quit/session" },
        { "<leader>s",     desc = "+search" },
        { "<leader>u",     desc = "+undo" },
        { "<leader>w",     desc = "+windows" },
        { "<leader>t",     desc = "+diagnostics/quickfix" },
      }
    })
  end,
}
