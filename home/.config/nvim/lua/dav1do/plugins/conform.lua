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
    format_on_save = function(bufnr)
      local ft = vim.bo[bufnr].filetype
      local always = { rust = true, lua = true, toml = true, python = true }
      if always[ft] then
        return { timeout_ms = 1000, lsp_format = "fallback" }
      end
      local prettier_fts = {
        javascript = true,
        typescript = true,
        javascriptreact = true,
        typescriptreact = true,
        json = true,
        markdown = true,
      }
      if prettier_fts[ft] then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local configs = {
          ".prettierrc",
          ".prettierrc.json",
          ".prettierrc.js",
          ".prettierrc.cjs",
          ".prettierrc.mjs",
          ".prettierrc.yaml",
          ".prettierrc.yml",
          ".prettierrc.toml",
          "prettier.config.js",
          "prettier.config.cjs",
          "prettier.config.mjs",
        }
        local found = vim.fs.find(configs, { upward = true, path = bufname })
        if #found > 0 then
          return { timeout_ms = 1000, lsp_format = "fallback" }
        end
        local pkg = vim.fs.find({ "package.json" }, { upward = true, path = bufname })[1]
        if pkg then
          local ok, contents = pcall(vim.fn.readfile, pkg)
          if
            ok
            and vim.tbl_contains(contents, function(l)
              return l:match('"prettier"%s*:')
            end, { predicate = true })
          then
            return { timeout_ms = 1000, lsp_format = "fallback" }
          end
        end
      end
      return nil
    end,
    formatters = {
      taplo = {
        append_args = { "-o", "indent_string=    " },
      },
    },
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
