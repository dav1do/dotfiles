local function overseer_project_cmd(kind)
  local cwd = vim.loop.cwd()
  local root = vim.fs.find({ "Cargo.toml", "pnpm-lock.yaml", "yarn.lock", "bun.lockb", "package.json" }, { upward = true, path = cwd })[1]

  local project
  if root then
    if root:sub(-#"Cargo.toml") == "Cargo.toml" then
      project = "rust"
    elseif root:sub(-#"pnpm-lock.yaml") == "pnpm-lock.yaml" then
      project = "pnpm-node"
    elseif root:sub(-#"yarn.lock") == "yarn.lock" then
      project = "yarn-node"
    elseif root:sub(-#"bun.lockb") == "bun.lockb" then
      project = "bun-node"
    elseif root:sub(-#"package.json") == "package.json" then
      project = "npm-node"
    end
  end

  local cmd, args
  if project == "rust" then
    if kind == "check" then
      cmd, args = "cargo", { "check" }
    elseif kind == "build" then
      cmd, args = "cargo", { "build" }
    elseif kind == "test" then
      cmd, args = "cargo", { "test" }
    end
  elseif project == "npm-node" then
    if kind == "check" then
      cmd, args = "npm", { "run", "lint" }
    elseif kind == "build" then
      cmd, args = "npm", { "run", "build" }
    elseif kind == "test" then
      cmd, args = "npm", { "test" }
    end
  elseif project == "pnpm-node" then
    if kind == "check" then
      cmd, args = "pnpm", { "run", "lint" }
    elseif kind == "build" then
      cmd, args = "pnpm", { "run", "build" }
    elseif kind == "test" then
      cmd, args = "pnpm", { "run", "test" }
    end
  elseif project == "yarn-node" then
    if kind == "check" then
      cmd, args = "yarn", { "lint" }
    elseif kind == "build" then
      cmd, args = "yarn", { "build" }
    elseif kind == "test" then
      cmd, args = "yarn", { "test" }
    end
  elseif project == "bun-node" then
    if kind == "check" then
      cmd, args = "bun", { "run", "lint" }
    elseif kind == "build" then
      cmd, args = "bun", { "run", "build" }
    elseif kind == "test" then
      cmd, args = "bun", { "test" }
    end
  end

  if not (cmd and args) then
    vim.notify("Overseer: no project command for " .. kind, vim.log.levels.WARN)
    return
  end

  local root_dir = root and vim.fs.dirname(root) or cwd
  local ok, overseer = pcall(require, "overseer")
  if not ok then
    vim.notify("Overseer: failed to load overseer.nvim", vim.log.levels.ERROR)
    return
  end

  local task = overseer.new_task({
    name = cmd .. " " .. table.concat(args, " "),
    cmd = cmd,
    args = args,
    cwd = root_dir,
  })
  task:start()
end

return {
  {
    "catppuccin",
    optional = true,
    opts = {
      integrations = { overseer = true },
    },
  },
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerOpen",
      "OverseerClose",
      "OverseerToggle",
      "OverseerSaveBundle",
      "OverseerLoadBundle",
      "OverseerDeleteBundle",
      "OverseerShell",
      "OverseerRun",
      "OverseerInfo",
      "OverseerBuild",
      "OverseerQuickAction",
      "OverseerTaskAction",
      "OverseerClearCache",
    },
    opts = {
      dap = false,
      templates = {
        "cargo",
        "just",
        "make",
        "npm",
        "shell",
        "tox",
        -- "vscode", -- this always breaks in cargo since i setup custom things
        "mage",
        "mix",
        "deno",
        "rake",
        "task",
        "composer",
        "cargo-make",
      },
      task_list = {
        direction = "right",
        render = function(task)
          local render = require("overseer.render")
          local ret = {
            render.status_and_name(task),
            render.join(render.duration(task), render.time_since_completed(task, { hl_group = "Comment" })),
          }
          vim.list_extend(ret, render.result_lines(task, { oneline = true }))
          return ret
        end,
        keymaps = {
          ["<C-h>"] = false,
          ["<C-j>"] = false,
          ["<C-k>"] = false,
          ["<C-l>"] = false,
        },
      },
      task_launcher = {
        -- Set keymap to false to remove default behavior
        -- You can add custom keymaps here as well (anything vim.keymap.set accepts)
        bindings = {
          i = {
            ["<C-s>"] = "Submit",
            ["<C-c>"] = "Cancel",
          },
          n = {
            ["<CR>"] = "Submit",
            ["<C-s>"] = "Submit",
            ["q"] = "Cancel",
            ["?"] = "ShowHelp",
          },
        },
      },
      form = {
        win_opts = {
          winblend = 0,
        },
      },
      confirm = {
        win_opts = {
          winblend = 0,
        },
      },
      task_win = {
        win_opts = {
          winblend = 0,
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>ow", "<cmd>OverseerToggle<cr>",      desc = "Task list" },
      { "<leader>oo", "<cmd>OverseerRun<cr>",         desc = "Run task" },
      { "<leader>oq", "<cmd>OverseerQuickAction<cr>", desc = "Action recent task" },
      { "<leader>oi", "<cmd>OverseerInfo<cr>",        desc = "Overseer Info" },
      { "<leader>ob", function() overseer_project_cmd("build") end, desc = "Project build" },
      { "<leader>ot", function() overseer_project_cmd("test") end,  desc = "Project test" },
      { "<leader>oc", function() overseer_project_cmd("check") end, desc = "Project check" },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>o", group = "overseer", desc = "+overseer" },
      },
    },
  },
  {
    "folke/edgy.nvim",
    optional = true,
    opts = function(_, opts)
      opts.right = opts.right or {}
      table.insert(opts.right, {
        title = "Overseer",
        ft = "OverseerList",
        open = function()
          require("overseer").open()
        end,
      })
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.consumers = opts.consumers or {}
      opts.consumers.overseer = require("neotest.consumers.overseer")
    end,
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      require("overseer").enable_dap()
    end,
  },
}
