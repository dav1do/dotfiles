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

-- Read package.json and return the first matching script name from the candidates list.
-- Returns nil (with a warning) if none match, so callers can fall back or abort.
local function find_node_script(root_dir, kind, candidates)
  local path = root_dir .. "/package.json"
  local f = io.open(path, "r")
  if not f then
    vim.notify("Overseer: cannot read " .. path, vim.log.levels.WARN)
    return nil
  end
  local content = f:read("*a")
  f:close()
  local ok, pkg = pcall(vim.json.decode, content)
  if not ok or not pkg or not pkg.scripts then
    vim.notify("Overseer: no scripts block in " .. path, vim.log.levels.WARN)
    return nil
  end
  for _, name in ipairs(candidates) do
    if pkg.scripts[name] then
      vim.notify("Overseer [" .. kind .. "]: using script '" .. name .. "'", vim.log.levels.INFO)
      return name
    end
  end
  -- nothing matched — list what is available so the user knows what to add to the priority list
  local available = vim.tbl_keys(pkg.scripts)
  table.sort(available)
  vim.notify(
    "Overseer [" .. kind .. "]: no matching script found.\n"
    .. "Tried: " .. table.concat(candidates, ", ") .. "\n"
    .. "Available: " .. table.concat(available, ", "),
    vim.log.levels.WARN
  )
  return nil
end

local function overseer_project_cmd(kind, to_trouble)
  local cwd = vim.uv.cwd()
  local root = vim.fs.find(
    { "Cargo.toml", "pnpm-lock.yaml", "yarn.lock", "bun.lockb", "package.json" },
    { upward = true, path = cwd }
  )[1]

  if not root then
    vim.notify("Overseer: no project root found", vim.log.levels.WARN)
    return
  end

  local filename = vim.fs.basename(root)
  local root_dir = vim.fs.dirname(root)
  local cmd, args

  if filename == "Cargo.toml" then
    -- Rust: check = cargo check, lint = clippy (read-only linting, not auto-fix)
    local cmds = {
      check      = { "cargo", { "check", "--workspace", "--all-targets", "--all-features" } },
      lint       = { "cargo", { "clippy", "--workspace", "--all-targets", "--all-features" } },
      long_check = { "cargo", { "clippy", "--workspace", "--all-targets", "--all-features", "--", "-D", "warnings" } },
      build      = { "cargo", { "build" } },
      test       = { "cargo", { "test" } },
    }
    if cmds[kind] then cmd, args = cmds[kind][1], cmds[kind][2] end

  else
    -- Node.js: detect package manager from lockfile
    local pm = ({ ["pnpm-lock.yaml"] = "pnpm", ["yarn.lock"] = "yarn", ["bun.lockb"] = "bun" })[filename] or "npm"

    if kind == "check" then
      -- Type-check only — read-only, never mutates files.
      -- "lint" is intentionally absent: most projects wire it to auto-fix.
      local script = find_node_script(root_dir, kind, {
        "check:types", "type-check", "typecheck", "types", "tsc",
      })
      if not script then return end
      cmd, args = pm, { "run", script }

    elseif kind == "lint" then
      -- Broader read-only checks (eslint --no-fix, stylelint, etc.).
      -- "lint" excluded for the same auto-fix reason above.
      local script = find_node_script(root_dir, kind, {
        "check", "check:all", "check:lint", "lint:check", "validate", "verify",
      })
      if not script then return end
      cmd, args = pm, { "run", script }

    elseif kind == "build" then
      cmd, args = pm, { "run", "build" }

    elseif kind == "test" then
      -- npm has a first-class `test` shorthand; others use `run test`
      cmd, args = pm == "npm" and { "npm", { "test" } } or { pm, { "run", "test" } }
    end
  end

  if not (cmd and args) then
    vim.notify("Overseer: no command for kind=" .. kind, vim.log.levels.WARN)
    return
  end

  local ok, overseer = pcall(require, "overseer")
  if not ok then
    vim.notify("Overseer: failed to load overseer.nvim", vim.log.levels.ERROR)
    return
  end

  local components = to_trouble
    and { "default", { "on_output_quickfix", open = false, set_diagnostics = true } }
    or  nil

  local task = overseer.new_task({
    name = cmd .. " " .. table.concat(args, " "),
    cmd = cmd,
    args = args,
    cwd = root_dir,
    components = components,
  })
  task:subscribe("on_complete", function(t)
    if to_trouble then
      vim.schedule(function()
        require("trouble").open({ mode = "diagnostics", focus = false })
      end)
    end
    if t.status ~= "FAILURE" then
      vim.defer_fn(function() t:dispose() end, 1000)
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
      { "<leader>tp", "<cmd>OverseerToggle<cr>",      desc = "Task list panel" },
      { "<leader>pt", overseer_run_picker,             desc = "Run task (picker)" },
      { "<leader>oq", "<cmd>OverseerTaskAction<cr>",    desc = "Task action" },
      { "<leader>ob", function() overseer_project_cmd("build") end, desc = "Project build" },
      { "<leader>ot", function() overseer_project_cmd("test") end,  desc = "Project test" },
      { "<leader>oc", function() overseer_project_cmd("check") end, desc = "Project check" },
      { "<leader>ol", function() overseer_project_cmd("lint") end,              desc = "Project lint (clippy)" },
      { "<leader>oC", function() overseer_project_cmd("long_check", true) end, desc = "Long check → Trouble" },
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
