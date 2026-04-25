return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
  config = function()
    require("trouble").setup({
      -- Default window for all trouble panels
      win = {
        type = "split",
        position = "right",
        size = 0.33,
        relative = "win",
        wo = { wrap = true }, -- wrap long diagnostics so full message is visible
      },
      preview = {
        type = "main",
      },
      keys = {
        -- Override K: show diagnostic detail float instead of man page
        K = "preview",
      },
      modes = {
        diagnostics = {},
        -- lsp/lsp_references: right panel, relative to current window.
        -- Triggered by gR — persistent, stays open for browsing.
        lsp = {},
        lsp_references = {},
        -- refs: bottom split for quick caller lookup via gr.
        -- Pressing <cr> jumps to the item and closes the panel.
        refs = {
          mode = "lsp_references",
          win = { type = "split", position = "bottom", size = 0.3 },
          keys = {
            ["<cr>"] = "jump_close",
          },
        },
        -- symbols: global sidebar anchored to editor right edge.
        -- auto_preview=false prevents the code window from jumping/scrolling
        -- as you navigate the symbol tree.
        symbols = {
          win = { type = "split", position = "right", size = 0.2, relative = "editor", wo = { winfixwidth = true } },
          auto_preview = false,
        },
      },
    })

    -- Auto-open symbols sidebar on first LspAttach in a session.
    -- After that, pinned=true keeps it following focus automatically.
    -- Closing it manually with <leader>ts keeps it closed for the rest of the session.
    local symbols_opened = true --TODO: disabling auto-open symbols for now
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function()
        if symbols_opened then
          return
        end
        symbols_opened = true
        vim.schedule(function()
          require("trouble").open({ mode = "symbols", focus = false })
        end)
      end,
    })
  end,
  cmd = "Trouble",
  keys = {
    {
      "<leader>td",
      "<cmd>Trouble diagnostics toggle focus=false<cr>",
      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>tb",
      "<cmd>Trouble diagnostics toggle filter.buf=0 focus=false<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>ts",
      "<cmd>Trouble symbols toggle focus=false pinned=true<cr>",
      desc = "Symbols (Trouble)",
    },
    {
      "<leader>tl",
      "<cmd>Trouble lsp toggle focus=false<cr>",
      desc = "LSP Definitions / references (Trouble)",
    },
    { "<leader>to", "<cmd>Trouble todo toggle<cr>", desc = "TODOs (Trouble)" },
    {
      "<leader>tf",
      "<cmd>Trouble todo toggle filter={tag={FIXME,BUG,HACK}}<cr>",
      desc = "FIXMEs (Trouble)",
    },
  },
}
