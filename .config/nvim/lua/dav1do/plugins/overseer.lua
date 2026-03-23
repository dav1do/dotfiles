local function overseer_run_picker()
  local overseer = require("overseer")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  require("overseer.template").list({ dir = vim.fn.getcwd() }, function(templates)
    pickers
      .new({}, {
        prompt_title = "Run Task",
        finder = finders.new_table({
          results = templates,
          entry_maker = function(tmpl)
            local display = tmpl.name
            if tmpl.desc then
              display = display .. "  " .. tmpl.desc
            end
            return { value = tmpl, display = display, ordinal = tmpl.name }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local sel = action_state.get_selected_entry()
            if sel then
              overseer.run_task({ name = sel.value.name })
            end
          end)
          return true
        end,
      })
      :find()
  end)
end

local function overseer_project_cmd(kind)
  local cwd = vim.uv.cwd()
  local root = vim.fs.find(
    { "Cargo.toml", "pnpm-lock.yaml", "yarn.lock", "bun.lockb", "package.json" },
    { upward = true, path = cwd }
  )[1]

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
      cmd, args = "cargo", { "check", "--workspace", "--all-targets", "--all-features" }
    elseif kind == "lint" then
      cmd, args = "cargo", { "clippy", "--workspace", "--all-targets", "--all-features" }
    elseif kind == "build" then
      cmd, args = "cargo", { "build" }
    elseif kind == "test" then
      cmd, args = "cargo", { "test" }
    end
  elseif project == "npm-node" then
    if kind == "check" or kind == "lint" then
      cmd, args = "npm", { "run", "lint" }
    elseif kind == "build" then
      cmd, args = "npm", { "run", "build" }
    elseif kind == "test" then
      cmd, args = "npm", { "test" }
    end
  elseif project == "pnpm-node" then
    if kind == "check" or kind == "lint" then
      cmd, args = "pnpm", { "run", "lint" }
    elseif kind == "build" then
      cmd, args = "pnpm", { "run", "build" }
    elseif kind == "test" then
      cmd, args = "pnpm", { "run", "test" }
    end
  elseif project == "yarn-node" then
    if kind == "check" or kind == "lint" then
      cmd, args = "yarn", { "lint" }
    elseif kind == "build" then
      cmd, args = "yarn", { "build" }
    elseif kind == "test" then
      cmd, args = "yarn", { "test" }
    end
  elseif project == "bun-node" then
    if kind == "check" or kind == "lint" then
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
  task:subscribe("on_complete", function(t)
    if t.status ~= "FAILURE" then
      vim.defer_fn(function()
        t:dispose()
      end, 1000)
    end
  end)
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
      "OverseerBuild",
      "OverseerQuickAction",
      "OverseerTaskAction",
      "OverseerClearCache",
    },
    opts = {
      dap = false,
      -- explicitly disable vscode template: it always warns about unsupported
      -- task types when a .vscode/tasks.json with cargo tasks is present
      disable_template_modules = { "overseer.template.vscode" },
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
        direction = "bottom",
        min_height = 10,
        max_height = 30,
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
      { "<leader>oo", overseer_run_picker,                desc = "Run task (picker)" },
      { "<leader>oq", "<cmd>OverseerTaskAction<cr>",    desc = "Task action" },
      { "<leader>ob", function() overseer_project_cmd("build") end, desc = "Project build" },
      { "<leader>ot", function() overseer_project_cmd("test") end,  desc = "Project test" },
      { "<leader>oc", function() overseer_project_cmd("check") end, desc = "Project check" },
      { "<leader>ol", function() overseer_project_cmd("lint") end, desc = "Project lint (clippy)" },
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
