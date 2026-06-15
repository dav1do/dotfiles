# Language tooling install

Stack: postgres, GCP, Docker, Pulumi (TypeScript), YAML, infra. Phased install. Each phase stands alone — install only what you need today.

After any install, verify with:
```bash
hx --health <language>
```
A `✓` in **Language Server** and **Formatter** columns means it works.

If you need to bounce a server inside helix without restart: `:lsp-restart`.

---

## Phase 0 — base tooling [DONE]

Already installed. Covers your existing `languages.toml`: rust, ts/tsx/js/jsx (vtsls), json, lua, python, toml, markdown formatting, bash formatting.

```bash
brew install prettier taplo shfmt ruff stylua
npm install -g @vtsls/language-server vscode-langservers-extracted
```

`vscode-langservers-extracted` also brought in `vscode-css-language-server`, `vscode-html-language-server`, `vscode-eslint-language-server` — helix auto-detects them when you open relevant files. No `languages.toml` change needed for CSS/HTML to get LSP support; only formatting (via prettier) is unconfigured for those types. Add later if you find yourself editing CSS in helix and missing format-on-save.

---

## Phase 1 — infra LSPs

Adds: yaml + GHA + k8s + GCP cloudbuild + compose schemas, dockerfile, bash diagnostics, markdown navigation.

### Install
```bash
brew install bash-language-server marksman
npm install -g yaml-language-server dockerfile-language-server-nodejs
```

This gives you four LSP binaries:
- `bash-language-server` — diagnostics for shell scripts
- `marksman` — markdown navigation (symbol outline, link nav, broken link detection)
- `yaml-language-server` — yaml + schema-aware completion for k8s, GHA, GCP cloudbuild, compose
- `docker-langserver` — Dockerfile completion + diagnostics

### `languages.toml` additions

Append to your existing `languages.toml`:

```toml
# bash — add LSP alongside existing shfmt formatter
[[language]]
name = "bash"
auto-format = true
language-servers = ["bash-language-server"]
formatter = { command = "shfmt", args = ["-i", "2", "-ci", "-bn"] }

# markdown — add marksman LSP; prettier formatter already present
[[language]]
name = "markdown"
auto-format = true
language-servers = ["marksman"]
formatter = { command = "prettier", args = ["--parser", "markdown"] }

# yaml — drop default ansible-language-server (not installed)
[[language]]
name = "yaml"
auto-format = true
language-servers = ["yaml-language-server"]

# yaml schemas — GHA, k8s, GCP cloudbuild, docker-compose
[language-server.yaml-language-server.config.yaml]
format.enable = true

[language-server.yaml-language-server.config.yaml.schemas]
"https://json.schemastore.org/github-workflow.json" = ".github/workflows/*.{yml,yaml}"
"https://json.schemastore.org/github-action.json" = ".github/actions/*/action.{yml,yaml}"
"https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.0/all.json" = "k8s/**/*.{yml,yaml}"
"https://json.schemastore.org/cloudbuild.json" = "cloudbuild*.{yml,yaml}"
"https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = ["docker-compose*.{yml,yaml}", "compose*.{yml,yaml}"]

# github-action — default routes to actions-language-server (not installed)
# and zizmor (not installed). Pin to just yaml-language-server.
[[language]]
name = "github-action"
language-servers = ["yaml-language-server"]

# dockerfile — default routes to both docker-langserver and docker-language-server.
# You only installed the first, so pin to it.
[[language]]
name = "dockerfile"
language-servers = ["docker-langserver"]
```

`[[language]]` overrides are non-destructive — helix merges your settings with its defaults. You don't lose tree-sitter, file-types, etc.

### Why this works for GCP / Pulumi

- **Pulumi (TypeScript)** — already covered by vtsls in Phase 0. No additional LSP needed.
- **GCP yaml** (GKE manifests, Cloud Build) — covered by yaml-language-server with the schemas above.
- **GCP IAM / policies (json)** — covered by vscode-json-language-server in Phase 0.
- **Terraform/HCL** — skipped because you use Pulumi instead. Add `terraform-ls` if that changes.

### Verify

```bash
hx --health bash markdown yaml dockerfile github-action
```

All five should show `✓` for Language Server. Open a `.github/workflows/*.yml` file — yaml-language-server should give completion on workflow keys (`runs-on`, `steps`, etc.) and red-underline invalid keys. That's the schema config working.

---

## Phase 2 — SQL / Postgres (optional)

Helix's default `languages.toml` wires no LSP for SQL. Three options:

| Option | Notes |
|---|---|
| Tree-sitter highlighting only | helix's default. Fine for ad-hoc queries; no completion, no schema awareness. |
| `postgrestools` (Supabase) | Postgres-specific LSP. Provides syntax check, completion, formatting. Younger project — less polished than rust-analyzer-tier servers, but actively developed. |
| `sqls` | Older general-SQL LSP. Mostly unmaintained. Skip. |

**My recommendation: stay on tree-sitter highlighting unless you spend several hours/week in `.sql` files.** The setup-to-payoff ratio for postgrestools isn't great if you mainly write occasional queries.

If you do want it:

```bash
# install — verify current install path at https://github.com/supabase-community/postgres_lsp
# (the project has rebranded; binary may be `postgrestools` or `postgres_lsp`)
npm install -g @postgrestools/postgrestools
# or download a binary release from the GitHub repo
```

Then add to `languages.toml`:

```toml
[language-server.postgrestools]
command = "postgrestools"
args = ["lsp-proxy"]   # check repo README — flag may have changed

[[language]]
name = "sql"
language-servers = ["postgrestools"]
auto-format = true
formatter = { command = "postgrestools", args = ["format", "--stdin-file-path", "query.sql"] }
```

For schema-aware completion (autocomplete table/column names), you point postgrestools at a live database via its config file. That's a project-by-project setup — not a global helix concern.

I'd skip until you feel the gap.

---

## Skipped (with reasons, for revisit)

| Tool | Reason |
|---|---|
| `actions-language-server` | yaml-language-server with the GHA schema covers most of the value. Less stable install path. |
| `docker-language-server` (Docker's newer one) | Distribution path moves around. Stick with the older, npm-installable `docker-langserver`. |
| `docker-compose-langserver` | yaml-language-server with the compose schema covers it. |
| `terraform-ls` | You use Pulumi, not Terraform. |
| `gopls` (Go) | Not in stack. |
| `pyright` / `basedpyright` | Not in stack; ruff covers your existing python config. |
| `tailwindcss-ls` | Not in stack. |
| `prisma-language-server` | Not in stack. |
| `graphql-language-service` | Not in stack. |
| `helm_ls` | Add only if you write Helm charts. |
| `zizmor` (GHA security scanner) | Optional polish. yaml-language-server already covers schema/syntax. |
| `nil` / `nixd` (Nix) | Add only if you do nix work. Your `~/mystuff/helix/flake.nix` is the helix project's own. |
| ESLint inline LSP | Skipped to keep TS file open fast. CI handles lint. Re-add if you want diagnostics in editor: add `vscode-eslint-language-server` to typescript/tsx/js/jsx language-servers list. |
| CSS/HTML prettier formatter | LSPs already work via Phase 0; only formatting is unconfigured. Add `[[language]]` blocks with prettier formatter if needed. |

---

## After install — common gotchas

- **PATH precedence**: if you previously added `~/.local/share/nvim/mason/bin` to PATH, remove that line from `.zshrc`. Brew binaries should win. Check with `which yaml-language-server` — should be in `/usr/local/bin/` or `/opt/homebrew/bin/` (or your nvm node prefix for npm-installed ones), not Mason.
- **vtsls + project tsconfig**: vtsls finds `typescript` via `node_modules/typescript/` first. If a project has no `node_modules`, it falls back to global. Generally don't need a global `npm install -g typescript`.
- **prettier config discovery**: prettier picks up `.prettierrc` from the project. No project config → defaults. Same as VS Code's behavior.
- **prettier version skew**: helix runs your global prettier, not the project's pinned one. Usually fine. If a project pins prettier 2.x and you have 3.x globally, format-on-save can produce diffs the project's `npm run format` wouldn't. Switch that project's `formatter` to `npx prettier` if it bites.
- **`:lsp-restart`** — bounces the LSP for the current buffer. Use after editing `languages.toml` (helix reloads config but LSPs need restart).
- **`:log-open`** — opens helix's log buffer. First place to look when an LSP silently fails.
- **Schema URLs going stale**: schemastore occasionally moves things. If `:log-open` shows yaml-language-server failing to fetch a schema, the URL in `languages.toml` is the fix.

---

## LSP loading

Helix starts language servers on demand — verified in `helix-lsp/src/lib.rs`. No LSP runs until you open a file of that type. Multiple files of the same language share one LSP instance. So configured-but-unused LSPs cost nothing at startup; the real cost is per-language at first open. Configure freely; install only what you use.
