return {
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
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
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
          map("v", c.show_versions_popup, "crates: versions")
          map("f", c.show_features_popup, "crates: features")
          map("d", c.show_dependencies_popup, "crates: dependencies")
          map("u", c.update_crate, "crates: update")
          map("U", c.upgrade_crate, "crates: upgrade")
          map("ua", c.update_all_crates, "crates: update all")
          map("uA", c.upgrade_all_crates, "crates: upgrade all")
          map("D", c.open_documentation, "crates: open docs")
          map("r", c.open_repository, "crates: open repository")
        end,
      })
    end,
  },
  {
    -- ferris is retained solely for view_memory_layout (struct offsets/sizes).
    -- Everything else ferris exposed is covered by rustaceanvim's :RustLsp view / syntaxTree.
    "vxpm/ferris.nvim",
    opts = {},
    keys = {
      {
        "<leader>crm",
        function()
          require("ferris.methods.view_memory_layout")()
        end,
        desc = "[m]emory layout",
      },
    },
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false,
    -- stylua: ignore
    keys = {
      { "<C-.>",       function() vim.cmd.RustLsp("codeAction") end,                        desc = "Rust Code Action" },
      -- K renders the diagnostic under cursor when one exists; otherwise plain hover.
      { "<leader>crd", function() vim.cmd.RustLsp("openDocs") end,                          desc = "Open [d]ocs (docs.rs)" },
      { "<leader>crD", function() vim.cmd.RustLsp("debuggables") end,                       desc = "[D]ebuggables" },
      { "<leader>cre", function() vim.cmd.RustLsp("expandMacro") end,                       desc = "[e]xpand macro" },
      { "<leader>crE", function() vim.cmd.RustLsp({ "explainError", "current" }) end,       desc = "[E]xplain error code" },
      { "<leader>crh", function() vim.cmd.RustLsp({ "view", "hir" }) end,                   desc = "view [h]ir" },
      { "<leader>crM", function() vim.cmd.RustLsp({ "view", "mir" }) end,                   desc = "view [M]ir" },
      { "<leader>crp", function() vim.cmd.RustLsp("parentModule") end,                      desc = "[p]arent module" },
      -- dump current LSP diagnostics (= cargo check output) into quickfix; navigate with ]q/[q
      { "<leader>crq", function() vim.diagnostic.setqflist({ severity = vim.diagnostic.severity.ERROR, open = true }) end, desc = "errors → [q]uickfix" },
      { "<leader>crr", function() vim.cmd.RustLsp("runnables") end,                         desc = "[r]unnables" },
      { "<leader>crR", function() vim.cmd.RustLsp("rebuildProcMacros") end,                 desc = "[R]ebuild proc macros" },
      { "<leader>crs", function() vim.cmd.RustLsp("syntaxTree") end,                        desc = "[s]yntax tree" },
      { "<leader>crt", function() vim.cmd.RustLsp("openCargo") end,                         desc = "Open Cargo.[t]oml" },
      { "<leader>crw", function() vim.cmd.RustLsp("reloadWorkspace") end,                   desc = "reload [w]orkspace" },
      {
        "<leader>crC",
        function()
          local client = vim.lsp.get_clients({ name = "rust_analyzer" })[1]
          if not client then
            vim.notify("rust-analyzer not attached", vim.log.levels.WARN)
            return
          end
          ---@type table
          local ra = client.config.settings["rust-analyzer"]
          ra.checkOnSave = not ra.checkOnSave
          client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
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
          -- visual gK: hover the type of the selected expression (iterator chains, etc.)
          vim.keymap.set("x", "gK", function()
            vim.cmd.RustLsp({ "hover", "range" })
          end, { buffer = bufnr, desc = "Rust: hover type of selection" })
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
              },
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
                "nix",
              },
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
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function(args)
          local name = vim.api.nvim_buf_get_name(args.buf)
          if not name:find("rustaceanvim") then
            return
          end

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
  },
}
