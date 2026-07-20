---
name: review-pr
description: >-
  Review a GitHub PR with parallel specialist reviewers, adversarially verify every finding
  against the code at head, re-rank severity, and post one review with inline comments via gh.
  Runs the fan-out and verify as a deterministic Workflow. Posts as a PENDING draft by default (visible only to
  David, who submits it himself in the GitHub UI); submits publicly only when he explicitly
  asks. Use when David says "review PR #N", "review this PR", or points at a PR URL and asks
  for feedback.
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Workflow", "Agent", "Write"]
---

# Review PR

A PR review is only as good as its weakest claim. Reviewer agents hallucinate line numbers,
miss context two files over, and inflate nits to blockers. This skill catches that before it
reaches the author: fan specialist reviewers out, **verify every finding against the code at
head**, then post a tight review the team reads as mentoring.

The fan-out-and-verify step runs as a deterministic **Workflow** (`fanout.workflow.js`, next
to this file): reviewers → per-file refute-pass (one verifier reads each file once and refutes
every claim on it) → dedupe, all parallel and schema-checked. Invoking this skill is the
explicit opt-in to run it — no separate "ultracode" signal needed.

If the `Workflow` tool isn't in your tool set (e.g. a non-Claude harness), **stop and tell
David** — don't improvise the fan-out by hand. The adversarial verify is the whole point of
this skill, and it won't survive an ad-hoc reimplementation.

The main loop always owns the parts that need its context or a side effect — pinning the head,
loading the diff, picking dimensions, composing, and posting via `gh`.

## Phase 1 — PR context, pinned at head

```bash
gh pr view <N> --json headRefName,baseRefName,title,url,body,number,additions,deletions
gh pr diff <N>
gh api user --jq .login                                       # your login — Phase 6 needs it
git fetch origin pull/<N>/head && git rev-parse FETCH_HEAD    # pin the head SHA NOW; later fetches clobber FETCH_HEAD
git rev-parse HEAD                                            # is the working copy already at head?
```

Shell vars don't survive across tool calls — note the SHA and substitute it literally for
`$HEAD_SHA` below. `{owner}/{repo}` in `gh api` auto-fills from the current repo; spell it out
(or pass `-R`) only for a PR in another repo.

Read the diff yourself — you compose and post from it, so it has to be in context. For PRs
above ~1500 changed lines, don't load it whole: get the file list with
`gh pr diff <N> --name-only`, pull patches as needed
(`gh api repos/{owner}/{repo}/pulls/<N>/files --paginate --jq '.[] | select(.filename=="<path>") | .patch'`),
and use only the relevant slice.

## Phase 2 — Read-only checkout at head

Reviewers and verifiers read code to follow callers and confirm claims. Give them a checkout
pinned at head — not the working tree, which may sit at another revision. Create a detached
worktree named `pr-<N>` at head (put it anywhere gitignored):

```bash
git worktree add --detach <worktree-path> "$HEAD_SHA"
```

The Workflow's verifiers `Read` at head, so this checkout is required. Fork PRs work too —
you already fetched the SHA.

## Phase 3 — Pick the dimensions the PR actually touches

One reviewer per dimension the PR **actually touches** — don't run all of them on a one-file
change. Prefer a purpose-built specialist (sharper rubric) over a generalist.

| Dimension (`key`) | Run when | specialist agent (if `pr-review-toolkit` installed) |
|---|---|---|
| `correctness` | always | `pr-review-toolkit:code-reviewer` |
| `silent-failure` | error handling, catch blocks, fallbacks, `Result`/`?` changed | `pr-review-toolkit:silent-failure-hunter` |
| `tests` | test files changed, or new logic lands untested | `pr-review-toolkit:pr-test-analyzer` |
| `types` | new types / changed invariants / enums / DTOs | `pr-review-toolkit:type-design-analyzer` |
| `comments` | non-trivial comments or doc comments added/changed | `pr-review-toolkit:comment-analyzer` |

**Confirm each specialist actually resolves before you name it — don't just trust the names.**
The `pr-review-toolkit:*` types exist only if that plugin is installed; passing an `agentType`
that doesn't resolve makes the Workflow stage throw and silently drops that whole dimension to
a `null` result (you'd lose, say, the correctness review entirely). Check: the agent types you
can spawn are listed in your own Agent/Task tool — only use ones that appear there.

The namespaced prefix matters — a bare `code-reviewer` collides with `feature-dev:code-reviewer`.
For any dimension whose specialist isn't present, omit `agentType` entirely and rely on the
inline `rubric` — the Workflow falls back to a general subagent.

**Each dimension is a full reviewer pass (~tens of k tokens), so pick the fewest that cover the
change.** Three well-aimed dimensions beat five redundant ones — dropping a marginal dimension
is the biggest cost lever there is. (Benchmarked slicing the diff per reviewer to save tokens;
it didn't move the needle — the diff is a small fraction of a reviewer's cost next to the source
files it reads from the worktree, and a narrower slice just induced more reads. Agent count is
what scales, not prompt size — so cut agents, not prompts.)

## Phase 4 — Run the Workflow

```
Workflow({
  scriptPath: "/Users/david/.claude/skills/review-pr/fanout.workflow.js",
  args: {
    prIntent: "<one or two lines: what the PR is trying to do>",
    diff: "<the full unified diff; reviewers see it whole, and the Workflow also parses it for
            inDiff + per-file verify patches>",
    worktreePath: "<worktree-path from Phase 2>",
    budgetTokens: 600000,   // optional hard ceiling on the run's output tokens; omit for no cap
    dimensions: [
      { key: "correctness", agentType: "pr-review-toolkit:code-reviewer", rubric: "<what to scrutinize here>" },
      // ...only the dimensions this PR touches
    ],
  },
})
```

It returns `{ findings, dropped, droppedReasons, budgetHit }`. Each finding is already verified,
deduped, and re-severitied; `inDiff` says whether it can attach inline. **Note `dropped` and a
few `droppedReasons`** — that count is a signal about agent quality, and David will ask.

**If `budgetHit` is true**, the cap stopped the run after the review phase: findings come back
**`unverified: true`** (no refute-pass ran). Don't post those inline — put them in the body
under an "unverified — hit the token cap" note, and tell David the cap was the limiter so he can
re-run with a higher `budgetTokens` or fewer dimensions if he wants the full pass.

## Phase 5 — Compose the review

**Before composing, scan findings for same-root-cause clusters.** If several nits or
suggestions trace to one underlying gap — missing error handling throughout, a pattern misused
in multiple places — name that pattern in the body at its true severity and demote the
individual inline comments to `nit`/`suggestion`. This synthesis belongs in the main loop.

**Top-level `body` is NOT a diff summary.** It is:
- A verdict line: `**Ready**` / `**Not ready** — <one-line reason>`. Any `blocking` finding ⇒ Not ready.
- Only cross-cutting feedback that can't attach to one line — a pattern across files, a missing
  test strategy, an architectural risk. No cross-cutting feedback ⇒ the body is just the verdict.

Never restate what changed or list files; that's in the PR.

**Inline comments** — one per finding where `inDiff` is true:
- `path` repo-relative, `line` the new-file number, `"side": "RIGHT"`.
- A finding with `inDiff: false` (real, but outside the diff or on a deleted line) goes in the
  body instead — inline comments can't attach there.

**Tone — read by the team as mentoring:**
- Explain the *why*, not just the fix. "Re-reads the file every call — cache it once" teaches
  more than "move this out of the loop."
- Label severity explicitly (`blocking` / `suggestion` / `nit`).
- Ask, don't assert, when it might be intentional. "Is this meant to handle the empty case?"
- No empty praise. One specific line worth reinforcing is fine; skip filler.

## Phase 6 — Post via gh (pending by default)

Post a **single** review (summary + all inline comments together). Build the payload in a
script — comment bodies are markdown full of quotes and backticks, and `json.dumps` escapes
correctly where hand-written JSON breaks. Write `$TMPDIR/pr-review-<N>.py` emitting to
`$TMPDIR/pr-review-<N>.json`:

```json
{
  "body": "**Not ready** — unhandled None on the auth path (see inline).",
  "comments": [
    {"path": "src/auth.rs", "line": 42, "side": "RIGHT", "body": "**blocking** — `session` is `None` when the cookie is expired; this unwraps and panics. Match and return 401 instead. Why: ..."}
  ]
}
```

**Default — pending (draft).** Omit `event` entirely: per the GitHub REST API a review created
with no `event` stays PENDING — visible only to David. He opens the PR, reads the draft, and
pulls the Approve / Comment / Request-changes lever himself. Default to this unless told otherwise.

**Submit immediately** only when David explicitly says "submit" / "post it" / "make it public".
Then add `"event": "COMMENT"` — never `APPROVE` / `REQUEST_CHANGES`; those are his call.

```bash
gh api repos/{owner}/{repo}/pulls/<N>/reviews --input "$TMPDIR/pr-review-<N>.json"
```

Pending-mode mechanics:
- Only **one** pending review per PR per user. Check first (login from Phase 1):
  `gh api repos/{owner}/{repo}/pulls/<N>/reviews --jq '.[] | select(.state=="PENDING" and .user.login=="<login>") | .node_id'`
- **If one exists, append — don't fail, don't create a second.** REST "create review" can't
  target an existing pending review, so use GraphQL: per comment,
  `addPullRequestReviewThread(input: {pullRequestReviewId: <node_id>, path, line, side: RIGHT, body})`;
  to revise the verdict, `updatePullRequestReview(input: {pullRequestReviewId: <node_id>, body})`.
  Introspect via `gh api graphql` first if unsure of the input fields — the schema shifts.
- The create response carries `"state"` (`PENDING` or `COMMENTED`). Report the mode that
  actually took effect, not the one you intended.

## After posting

Remove the worktree if you created one: `git worktree remove --force <worktree-path>`.

Report: mode (pending draft vs submitted), the verdict, findings by tier, and how many findings
the refute-pass dropped and why. For pending mode, give David the PR URL and tell him to open it
and submit when ready. Keep it short.
