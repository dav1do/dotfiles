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
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        cmp = { enabled = true },
      },
    },
    keys = {
      { "<leader>cv", function() require("crates").show_versions_popup() end, desc = "Show crate [v]ersions" },
      { "<leader>cf", function() require("crates").show_features_popup() end, desc = "Show crate [f]eatures" },
      { "<leader>cd", function() require("crates").show_dependencies_popup() end, desc = "Show crate [d]ependencies" },
      { "<leader>cu", function() require("crates").update_crate() end, desc = "[u]pdate create" },
      { "<leader>cU", function() require("crates").upgrade_crate() end, desc = "[U]pgrade crate" },
      { "<leader>ca", function() require("crates").update_all_crates() end, desc = "Update [a]ll crates" },
      { "<leader>cA", function() require("crates").upgrade_all_crates() end, desc = "Upgrade [A]ll crates" },
      { "<leader>cH", function() require("crates").open_homepage() end, desc = "Crate [H]omepage" },
      { "<leader>cD", function() require("crates").open_documentation() end, desc = "Crate [D]oc page" },
      { "<leader>cR", function() require("crates").open_repository() end, desc = "Crate [R]eposi:tory" },
    }
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
      { "<leader>crs", function() require("ferris.methods.view_syntax_tree")() end,   desc = "View Item [S]yntax Tree" },
    }
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false,
    keys = {
      { "<leader>cA",  function() vim.cmd.RustLsp("codeAction") end,        desc = "Rust Code [A]ction" },
      { "<leader>crd", function() vim.cmd.RustLsp("debuggables") end,       desc = "Rust [D]ebuggables" },
      { "<leader>cre", function() vim.cmd.RustLsp("expandMacro") end,       desc = "[E]xpand Macro" },
      { "<leader>crr", function() vim.cmd.RustLsp("rebuildProcMacros") end, desc = "[R]ebuild proc macros" },
      { "<leader>crs", function() vim.cmd.RustLsp("sytaxTree") end,         desc = "[S]yntax tree" },
      { "<leader>crt", function() vim.cmd.RustLsp("openCargo") end,         desc = "Open Cargo.[t]oml" },
    },
    opts = {
      server = {
        on_attach = function(_, bufnr)
          -- switched keymaps to keys object to get better which key support
        end,
        default_settings = {
          -- rust-analyzer language server configuration
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = {
                enable = true,
              },
            },
            -- Add clippy lints for Rust.
            checkOnSave = true,
            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
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
      if vim.fn.executable("rust-analyzer") == 0 then
        vim.health.error(
          "**rust-analyzer** not found in PATH, please install it.\nhttps://rust-analyzer.github.io/",
          { title = "rustaceanvim" }
        )
      end
      vim.g.rustaceanvim = {
        server = {
          capabilities = require('cmp_nvim_lsp').default_capabilities(),
        },
      }
    end,
  }
}
