return
{
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>cr", group = "rust" },
      },
    },
  },
  {
    "Saecki/crates.nvim",
    event = { "BufReadPost Cargo.toml", "BufNewFile Cargo.toml" },
    opts = {
      completion = {
        cmp = { enabled = true },
      },
    },
    config = function(_, opts)
      require("crates").setup(opts)
      -- buffer-local keymaps via <localleader> — only active in Cargo.toml
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "Cargo.toml",
        callback = function(args)
          local buf = args.buf
          local c = require("crates")
          local map = function(key, fn, desc)
            vim.keymap.set("n", "<localleader>" .. key, fn, { buffer = buf, desc = desc })
          end
          map("v",  c.show_versions_popup,     "crates: versions")
          map("f",  c.show_features_popup,     "crates: features")
          map("d",  c.show_dependencies_popup, "crates: dependencies")
          map("u",  c.update_crate,            "crates: update")
          map("U",  c.upgrade_crate,           "crates: upgrade")
          map("ua", c.update_all_crates,       "crates: update all")
          map("uA", c.upgrade_all_crates,      "crates: upgrade all")
          map("D",  c.open_documentation,      "crates: open docs")
          map("r",  c.open_repository,         "crates: open repository")
        end,
      })
    end,
  },
  {
    'vxpm/ferris.nvim',
    opts = {},
    -- stylua: ignore
    keys = {
      { "<leader>crl", function() require("ferris.methods.view_memory_layout")() end, desc = "View Memory [L]ayout" },
      { "<leader>crm", function() require("ferris.methods.view_mir")() end,           desc = "View [M]ir" },
      { "<leader>crh", function() require("ferris.methods.view_hir")() end,           desc = "View [H]ir" },
      { "<leader>cri", function() require("ferris.methods.view_item_tree")() end,     desc = "View [I]tem Tree" },
      { "<leader>crS", function() require("ferris.methods.view_syntax_tree")() end,   desc = "View Item [S]yntax Tree (ferris)" },
    }
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false,
    keys = {
      { "<C-.>",        function() vim.cmd.RustLsp("codeAction") end,                     desc = "Rust Code Action" },
      -- diagnostic rendering: K renders the diagnostic under cursor; <leader>ce cycles to next.
      -- Guard: if focus is in a sidebar/panel, wincmd p returns to the code window first so
      -- the horizontal split opens below code, not below the sidebar.
      { "<leader>ce", function()
          if #vim.lsp.get_clients({ bufnr = 0, name = "rust_analyzer" }) == 0 then
            vim.notify("rust-analyzer not attached", vim.log.levels.WARN)
            return
          end
          if vim.bo.buftype ~= "" then vim.cmd("wincmd p") end
          vim.cmd.RustLsp({ "renderDiagnostic", "cycle" })
        end, desc = "[rust] Next diagnostic (cargo-style)" },
      { "<leader>cE",   function() vim.cmd.RustLsp({ "explainError",     "current" }) end, desc = "[rust] Explain error code" },
      -- dump current LSP diagnostics (= cargo check output) into quickfix; navigate with ]q/[q
      { "<leader>crq", function()
          vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR, open = true })
        end, desc = "[R]ust errors → quickfix" },
      { "<leader>crd",  function() vim.cmd.RustLsp("debuggables") end,                     desc = "Rust [D]ebuggables" },
      { "<leader>cre",  function() vim.cmd.RustLsp("expandMacro") end,                     desc = "[E]xpand Macro" },
      { "<leader>crr", function() vim.cmd.RustLsp("rebuildProcMacros") end, desc = "[R]ebuild proc macros" },
      { "<leader>crs", function() vim.cmd.RustLsp("syntaxTree") end,        desc = "[S]yntax tree" },
      { "<leader>crt", function() vim.cmd.RustLsp("openCargo") end,         desc = "Open Cargo.[t]oml" },
      {
        "<leader>crC",
        function()
          local clients = vim.lsp.get_clients({ name = "rust_analyzer" })
          if #clients == 0 then
            vim.notify("rust-analyzer not attached", vim.log.levels.WARN)
            return
          end
          local ra = clients[1].config.settings["rust-analyzer"]
          ra.checkOnSave = not ra.checkOnSave
          clients[1].notify("workspace/didChangeConfiguration", { settings = clients[1].config.settings })
          vim.notify("rust-analyzer checkOnSave: " .. tostring(ra.checkOnSave))
        end,
        desc = "Toggle [C]heck on save",
      },
    },
    opts = {
      tools = {
        float_win_config = {
          -- auto_focus: cursor lands inside the float so <CR> / q work immediately
          auto_focus = true,
          -- horizontal opens below current window (vertical goes to editor edge)
          open_split = "horizontal",
        },
      },
      server = {
        on_attach = function(_, bufnr)
          -- switched keymaps to keys object to get better which key support
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end,
        default_settings = {
          -- rust-analyzer language server configuration
          ["rust-analyzer"] = {
            cargo = {
              -- allFeatures causes RA to analyse every feature combination — more
              -- complete but generates extra diagnostics for non-default code paths.
              -- Set to true if you regularly work across feature flags; false otherwise.
              allFeatures = false,
              loadOutDirsFromCheck = true,
              buildScripts = {
                enable = true,
              }
            },
            check = { command = "check" },
            diagnostics = {
              -- Suppress RA's own analysis-layer noise; cargo check surfaces the real errors.
              -- "inactive-code"        — cfg-gated blocks grayed out (visual noise)
              -- "unresolved-proc-macro"— proc-macro expansion failed; cargo check shows the real error
              -- "syntax-error"         — RA's parser generates cascading parse errors after any real
              --                          error; cargo check gives the canonical error with spans
              -- "unresolved-macro-call"— similar cascade when a macro reference can't be resolved
              disabled = {
                "inactive-code",
                "unresolved-proc-macro",
                "syntax-error",
                "unresolved-macro-call",
              },
            },
            files = {
              exclude = {
                ".direnv",
                ".devenv",
                "target",
                "node_modules",
                "nix"
              }
            },
            testExplorer = true,
            inlayHints = {
              closureReturnTypeHints = { enable = "with_block" },
              lifetimeElisionHints = { enable = "skip_trivial" },
              typeHints = { enable = true },
              rangeExclusiveHints = { enable = true },
              -- implicitDrops = { enable = false },
              genericParameterHints = { const = { enable = true }, type = { enable = true } },
            },
            -- Add clippy lints for Rust.
            checkOnSave = true,
            procMacro = {
              enable = true,
              ignored = {
                -- ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})

      -- Manage the renderDiagnostic / explainError terminal split:
      --   • wincmd J  — move to full-width bottom split regardless of where rustaceanvim opened it
      --   • ra_diag_buf tracking — close any previous terminal before a new one appears
      --     (handles K-then-<leader>ce, double-K, etc. without a "already connected" error)
      local ra_diag_buf = nil
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function(args)
          local name = vim.api.nvim_buf_get_name(args.buf)
          if not name:find("rustaceanvim") then return end

          -- close the previous terminal if still open
          if ra_diag_buf and vim.api.nvim_buf_is_valid(ra_diag_buf) then
            for _, w in ipairs(vim.fn.win_findbuf(ra_diag_buf)) do
              pcall(vim.api.nvim_win_close, w, true)
            end
            pcall(vim.api.nvim_buf_delete, ra_diag_buf, { force = true })
          end
          ra_diag_buf = args.buf

          vim.cmd("wincmd J") -- pull to full-width bottom, regardless of sidebar layout
          vim.cmd("resize 18")

          vim.keymap.set("n", "q", function()
            vim.cmd("close")
            pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
            ra_diag_buf = nil
          end, { buffer = args.buf, nowait = true, desc = "Close diagnostic split" })
        end,
      })
    end,
  }
}
