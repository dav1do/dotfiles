local get_args = function(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
  config = vim.deepcopy(config)
  config.args = function()
    local new_args = vim.fn.input("Run with args: ", table.concat(args, " "))
    return vim.split(vim.fn.expand(new_args), " ")
  end
  return config
end

return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
      -- auto-install formatters used by conform
      local mr = require("mason-registry")
      local formatters = { "prettier", "stylua", "ruff", "taplo" }
      mr.refresh(function()
        for _, name in ipairs(formatters) do
          local ok, pkg = pcall(mr.get_package, name)
          if ok and not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", -- source for text in buffer
      "hrsh7th/cmp-path", -- source for file system paths
      {
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!).
        build = "make install_jsregexp",
      },
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "saadparwaiz1/cmp_luasnip", -- for autocompletion
      "rafamadriz/friendly-snippets", -- useful snippets
      "onsails/lspkind.nvim", -- vs-code like pictograms
      -- "zbirenbaum/copilot.lua",
      -- "zbirenbaum/copilot-cmp",
    },
    config = function()
      vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
      local cmp = require("cmp")
      local defaults = require("cmp.config.default")()
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      cmp.setup({
        auto_brackets = {
          "rust",
        }, -- configure any filetype to auto add brackets
        completion = {
          completeopt = "menu,menuone,noinsert", --,noselect
        },
        preselect = cmp.PreselectMode.Item or cmp.PreselectMode.None,
        snippet = { -- configure how nvim-cmp interacts with snippet engine
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
          ["<C-q>"] = cmp.mapping.abort(), -- close completion window
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        -- sources for autocompletion
        sources = cmp.config.sources({
          -- { name = "copilot" },
          { name = "nvim_lsp" },
          { name = "luasnip" }, -- snippets
          { name = "buffer" }, -- text within current buffer
          { name = "path" }, -- file system paths
        }, {
          { name = "buffer" },
        }),
        -- configure lspkind for vs-code like pictograms in completion menu
        formatting = {
          format = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
        experimental = {
          ghost_text = {
            hl_group = "CmpGhostText",
          },
        },
        sorting = defaults.sorting,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    cmd = { "LspInfo", "LspInstall", "LspStart" },
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp" },
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
    },
    opts = function()
      ---@class PluginLspOpts
      local ret = {
        -- options for vim.diagnostic.config()
        ---@type vim.diagnostic.Opts
        diagnostics = {
          -- underline errors and warnings; hints/info don't need squiggles
          underline = { severity = { min = vim.diagnostic.severity.WARN } },
          update_in_insert = false,
          virtual_text = false,
          severity_sort = true,
          -- suppress gutter signs for HINT and INFO — too much noise
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = " ",
              [vim.diagnostic.severity.WARN] = " ",
              [vim.diagnostic.severity.HINT] = " ",
              [vim.diagnostic.severity.INFO] = " ",
            },
            severity = { min = vim.diagnostic.severity.WARN },
          },
          -- float: source tells you which LSP is complaining (rust-analyzer, eslint, …)
          float = {
            border = "rounded",
            source = true,
            header = "",
            prefix = "",
          },
        },
        inlay_hints = {
          enabled = true,
          exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
        },
        -- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
        -- Be aware that you also will need to properly configure your LSP server to
        -- provide the code lenses.
        codelens = {
          enabled = false,
        },
        -- Enable lsp cursor word highlighting
        document_highlight = {
          enabled = true,
        },
        -- add any global capabilities here
        capabilities = {
          workspace = {
            fileOperations = {
              didRename = true,
              willRename = true,
            },
          },
        },
        -- LSP Server Settings
        ---@type lspconfig.options
        servers = {
          tsserver = {
            enabled = false,
          },
          ts_ls = {
            enabled = false,
          },
          vtsls = {
            -- explicitly add default filetypes, so that we can extend
            -- them in related extras
            filetypes = {
              "javascript",
              "javascriptreact",
              "javascript.jsx",
              "typescript",
              "typescriptreact",
              "typescript.tsx",
            },
            settings = {
              complete_function_calls = true,
              vtsls = {
                enableMoveToFileCodeAction = true,
                autoUseWorkspaceTsdk = true,
                experimental = {
                  completion = {
                    enableServerSideFuzzyMatch = true,
                  },
                },
              },
              typescript = {
                updateImportsOnFileMove = { enabled = "always" },
                suggest = {
                  completeFunctionCalls = true,
                },
                inlayHints = {
                  enumMemberValues = { enabled = true },
                  functionLikeReturnTypes = { enabled = true },
                  parameterNames = { enabled = "literals" },
                  parameterTypes = { enabled = true },
                  propertyDeclarationTypes = { enabled = true },
                  variableTypes = { enabled = false },
                },
              },
            },
          },
          lua_ls = {
            -- mason = false, -- set to false if you don't want this server to be installed with mason
            -- Use this to add any additional keymaps
            -- for specific lsp servers
            -- ---@type LazyKeysSpec[]
            -- keys = {},
            settings = {
              Lua = {
                workspace = {
                  checkThirdParty = false,
                },
                codeLens = {
                  enable = true,
                },
                completion = {
                  callSnippet = "Replace",
                },
                doc = {
                  privateName = { "^_" },
                },
                hint = {
                  enable = true,
                  setType = false,
                  paramType = true,
                  paramName = "Disable",
                  semicolon = "Disable",
                  arrayIndex = "Disable",
                },
              },
            },
          },
        },
      }
      return ret
    end,
    config = function(_, opts)
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      local lsp_defaults = require("lspconfig").util.default_config

      -- Add cmp_nvim_lsp capabilities settings to lspconfig
      -- This should be executed before you configure any language server
      lsp_defaults.capabilities =
        vim.tbl_deep_extend("force", lsp_defaults.capabilities, require("cmp_nvim_lsp").default_capabilities())

      -- LspAttach is where you enable features that only work
      -- if there is a language server active in the file
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP actions",
        callback = function(event)
          local buf = { buffer = event.buf }

          -- enable inlay hints for this buffer unless the filetype is excluded
          if opts.inlay_hints.enabled then
            local ft = vim.bo[event.buf].filetype
            if not vim.tbl_contains(opts.inlay_hints.exclude or {}, ft) then
              vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            end
          end

          -- K: cargo-style renderDiagnostic for Rust (full context spans), plain float otherwise.
          -- Dedup/positioning is handled by the TermOpen autocmd in rust.lua.
          vim.keymap.set("n", "K", function()
            local lnum = vim.fn.line(".") - 1
            local diags = vim.diagnostic.get(0, { lnum = lnum })
            if #diags > 0 and #vim.lsp.get_clients({ bufnr = 0, name = "rust_analyzer" }) > 0 then
              vim.cmd.RustLsp({ "renderDiagnostic", "current" })
            elseif #diags > 0 then
              vim.diagnostic.open_float(nil, { focus = false, scope = "line" })
            else
              vim.lsp.buf.hover()
            end
          end, { buffer = event.buf, desc = "Hover / diagnostic float" })
          vim.keymap.set(
            "n",
            "gd",
            "<cmd>lua vim.lsp.buf.definition()<cr>",
            { buffer = event.buf, desc = "[lsp] Definition" }
          )
          vim.keymap.set(
            "n",
            "gD",
            "<cmd>lua vim.lsp.buf.declaration()<cr>",
            { buffer = event.buf, desc = "[lsp] Declaration" }
          )
          vim.keymap.set(
            "n",
            "gi",
            "<cmd>lua vim.lsp.buf.implementation()<cr>",
            { buffer = event.buf, desc = "[lsp] Implementation" }
          )
          vim.keymap.set(
            "n",
            "go",
            "<cmd>lua vim.lsp.buf.type_definition()<cr>",
            { buffer = event.buf, desc = "[lsp] Type definition" }
          )
          -- note: gr removed — Neovim 0.11+ uses gr* prefix for built-in LSP keymaps
          -- (grr=references, grn=rename, gra=code_action, gri=impl, grt=type_def, grx=codelens)
          -- gR still works for the Trouble lsp_references panel
          vim.keymap.set(
            "n",
            "gR",
            "<cmd>Trouble lsp_references toggle<cr>",
            { buffer = event.buf, desc = "[trouble] References panel" }
          )
          vim.keymap.set(
            "n",
            "gS",
            "<cmd>lua vim.lsp.buf.signature_help()<cr>",
            { buffer = event.buf, desc = "[lsp] Signature help" }
          )
          vim.keymap.set(
            "n",
            "<F2>",
            "<cmd>lua vim.lsp.buf.rename()<cr>",
            { buffer = event.buf, desc = "[lsp] Rename symbol" }
          )
          -- smart code action: rust-analyzer provides richer actions in .rs files
          vim.keymap.set("n", "<leader>ca", function()
            local clients = vim.lsp.get_clients({ bufnr = 0, name = "rust_analyzer" })
            if #clients > 0 then
              vim.cmd.RustLsp("codeAction")
            else
              vim.lsp.buf.code_action()
            end
          end, { buffer = event.buf, desc = "Code action" })
          vim.keymap.set(
            "n",
            "<leader>pn",
            "<cmd>Navbuddy<cr>",
            { buffer = event.buf, desc = "Code structure (Navbuddy)" }
          )
          -- vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
          -- vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
        end,
      })

      if opts.codelens.enabled then
        vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
          callback = function(e)
            vim.lsp.codelens.refresh({ bufnr = e.buf })
          end,
        })
      end

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "eslint",
          "gopls",
          "html",
          "cssls",
          "vtsls",
          "bashls",
        },
        handlers = {
          -- default handler: applies server-specific opts from the opts.servers table
          function(server_name)
            local server_opts = vim.tbl_deep_extend("force", {}, (opts.servers or {})[server_name] or {})
            if server_opts.enabled == false then
              return
            end
            server_opts.enabled = nil
            require("lspconfig")[server_name].setup(server_opts)
            -- until https://github.com/neovim/neovim/pull/30999 lands
            for _, method in ipairs({ "textDocument/diagnostic", "workspace/diagnostic" }) do
              local default_diagnostic_handler = vim.lsp.handlers[method]
              vim.lsp.handlers[method] = function(err, result, context, config)
                if err ~= nil and err.code == -32802 then
                  return
                end
                return default_diagnostic_handler(err, result, context, config)
              end
            end
          end,
          -- vtsls: copy typescript settings to javascript before setup
          vtsls = function()
            local server_opts = vim.tbl_deep_extend("force", {}, opts.servers.vtsls or {})
            if server_opts.settings and server_opts.settings.typescript then
              server_opts.settings.javascript =
                vim.tbl_deep_extend("force", {}, server_opts.settings.typescript, server_opts.settings.javascript or {})
            end
            require("lspconfig").vtsls.setup(server_opts)
          end,
        },
      })
    end,
  },
  {
    "mfussenegger/nvim-dap",
    recommended = true,
    desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",

    dependencies = {
      "rcarriga/nvim-dap-ui",
      -- virtual text for the debugger
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
    },

    -- stylua: ignore
    keys = {
      { "<leader>d",  "",                                                                                   desc = "+debug",                 mode = { "n", "v" } },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end,                                    desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end,                                             desc = "Continue" },
      { "<leader>da", function() require("dap").continue({ before = get_args }) end,                        desc = "Run with Args" },
      { "<leader>dC", function() require("dap").run_to_cursor() end,                                        desc = "Run to Cursor" },
      { "<leader>dg", function() require("dap").goto_() end,                                                desc = "Go to Line (No Execute)" },
      { "<leader>di", function() require("dap").step_into() end,                                            desc = "Step Into" },
      { "<leader>dj", function() require("dap").down() end,                                                 desc = "Down" },
      { "<leader>dk", function() require("dap").up() end,                                                   desc = "Up" },
      { "<leader>dl", function() require("dap").run_last() end,                                             desc = "Run Last" },
      { "<leader>do", function() require("dap").step_out() end,                                             desc = "Step Out" },
      { "<leader>dO", function() require("dap").step_over() end,                                            desc = "Step Over" },
      { "<leader>dp", function() require("dap").pause() end,                                                desc = "Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end,                                          desc = "Toggle REPL" },
      { "<leader>ds", function() require("dap").session() end,                                              desc = "Session" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end,                                     desc = "Widgets" },
    },

    config = function()
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      -- setup dap config by VsCode launch.json file
      -- local vscode = require("dap.ext.vscode")
      -- local json = re quire("plenary.json")
      -- vscode.json_decode = function(str)
      --   return vim.json.decode(json.json_strip_comments(str))
      -- end
    end,
  },

  -- fancy UI for the debugger
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    -- stylua: ignore
    keys = {
      { "<leader>du",  function() require("dapui").open() end,   desc = "Dap UI open" },
      { "<leader>dut", function() require("dapui").toggle() end, desc = "Dap UI toggle" },
      { "<leader>de",  function() require("dapui").eval() end,   desc = "Eval",         mode = { "n", "v" } },
    },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
  },

  -- mason.nvim integration
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = "mason.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
      },
    },
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/nvim-nio", "nvim-lua/plenary.nvim" },
    -- stylua: ignore
    keys = {
      { "<leader>Tr", function() require("neotest").run.run() end,                                desc = "Run nearest test" },
      { "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end,              desc = "Run file (module)" },
      { "<leader>Tl", function() require("neotest").run.run_last() end,                           desc = "Run last test" },
      { "<leader>Tt", function() vim.cmd.RustLsp("testables") end,                               desc = "Rust testables picker" },
      { "<leader>Ts", function() require("neotest").summary.toggle() end,                         desc = "Toggle summary" },
      { "<leader>To", function() require("neotest").output.open({ enter = true, last_run = true }) end, desc = "Open output (float)" },
      { "<leader>TO", function() require("neotest").output_panel.toggle() end,                       desc = "Toggle output panel (streaming)" },
      { "<leader>Tx", function() require("neotest").run.stop() end,                               desc = "Stop" },
      { "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end,            desc = "Debug nearest test" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("rustaceanvim.neotest"),
        },
        -- auto-pop a brief float after each run without stealing focus;
        -- use <leader>To for the full output float on demand
        output = {
          enabled = true,
          open_on_run = "short",
        },
        floating = {
          border = "rounded",
          max_height = 0.8,
          max_width = 0.8,
        },
        -- streaming panel stays at bottom for long runs, but is no longer primary
        output_panel = {
          enabled = true,
          open = "botright split | resize 15",
        },
        -- summary opens left of code (right of nvim-tree when present)
        summary = {
          open = "leftabove vsplit | vertical resize 40",
        },
      })

      -- q to close each neotest panel — all three are modifiable=false by
      -- design, so pressing q normally hits "E21: Cannot make changes"
      local close_maps = {
        ["neotest-summary"] = function()
          require("neotest").summary.toggle()
        end,
        ["neotest-output-panel"] = function()
          require("neotest").output_panel.toggle()
        end,
        ["neotest-output"] = function()
          vim.api.nvim_win_close(0, true)
        end,
      }
      vim.api.nvim_create_autocmd("FileType", {
        pattern = vim.tbl_keys(close_maps),
        callback = function(e)
          local close = close_maps[vim.bo[e.buf].filetype]
          vim.keymap.set("n", "q", close, { buffer = e.buf, nowait = true, desc = "Close panel" })
        end,
      })
    end,
  },
}
