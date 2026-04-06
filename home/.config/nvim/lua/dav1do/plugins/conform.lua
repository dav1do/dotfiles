return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      desc = "Format code",
      mode = { "n", "v" },
    },
  },
  opts = {
    formatters_by_ft = {
      json = { "prettier" },
      lua = { "stylua" },
      markdown = { "prettier" },
      python = { "ruff_format" },
      rust = { "rustfmt", lsp_format = "fallback" },
      toml = { "taplo" },
      javascript = { "prettier", stop_after_first = true },
      typescript = { "prettier", stop_after_first = true },
      javascriptreact = { "prettier", stop_after_first = true },
      typescriptreact = { "prettier", stop_after_first = true },
    },
  },
}
