return {
  -- Better `vim.notify()`
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    opts = {
      stages = "static",
      timeout = 5000,
      top_down = true,
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.75)
      end,
      on_open = function(win)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end,
    },
  },
  { "MunifTanjim/nui.nvim", lazy = true },
  -- Highly experimental plugin that completely replaces the UI for messages, cmdline and the popupmenu.
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = {
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              -- { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
        {
          filter = {
            event = "msg_show",
            kind = "",
            any = {
              { find = "written" },
              { find = "yanked" },
              { find = "copied" },
            },
          },
          opts = { skip = true },
        },
        -- {
        --   view = "notify",
        --   filter = { event = "msg_showmode" },
        -- },
        -- view = "mini",
        -- },
      },
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = false, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>nl", function() require("noice").cmd("last") end,    desc = "Last message" },
      { "<leader>nh", function() require("noice").cmd("history") end, desc = "Message history" },
      { "<leader>na", function() require("noice").cmd("all") end,     desc = "All messages" },
      { "<leader>np", function() require("noice").cmd("pick") end,    desc = "Pick message (searchable)" },
      { "<leader>nd", function()
          require("noice").cmd("dismiss")
          pcall(function() require("notify").dismiss({ silent = true, pending = true }) end)
        end, desc = "Dismiss messages" },
      { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect cmdline to split" },
      { "<C-f>", function() if not require("noice.lsp").scroll(4)  then return "<C-f>" end end, silent = true, expr = true, mode = { "i", "n", "s" }, desc = "Scroll doc forward" },
      { "<C-b>", function() if not require("noice.lsp").scroll(-4) then return "<C-b>" end end, silent = true, expr = true, mode = { "i", "n", "s" }, desc = "Scroll doc backward" },
    },
    config = function(_, opts)
      -- HACK: noice shows messages from before it was enabled,
      -- but this is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.o.filetype == "lazy" then
        vim.cmd([[messages clear]])
      end
      require("noice").setup(opts)
    end,
  },
}
