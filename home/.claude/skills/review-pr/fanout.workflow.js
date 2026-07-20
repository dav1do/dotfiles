export const meta = {
  name: 'review-pr-fanout',
  description: 'Fan out specialist reviewers over a PR diff, adversarially verify every finding against the code at head, dedupe. Returns verified findings only.',
  phases: [
    { title: 'Review', detail: 'one specialist agent per touched dimension' },
    { title: 'Verify', detail: 'one independent refuter per file, reads it once, refutes all its findings' },
  ],
}

// args, supplied by the skill's main loop:
// {
//   prIntent:     string,                          // what the PR is trying to do
//   diff:         string,                          // FULL unified diff; reviewers see it whole. Also parsed
//                                                   //   here for inDiff + per-file verify patches.
//   worktreePath: string,                          // read-only checkout pinned at the PR head SHA
//   dimensions:   [{ key, agentType, rubric }],    // only the dimensions this PR actually touches
//   budgetTokens: number,                          // optional hard ceiling on this run's output tokens; if the
//                                                   //   review phase alone blows it, verify is skipped and
//                                                   //   findings come back flagged unverified (safe, loud).
// }

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'path', 'line', 'claim', 'why', 'fix'],
        properties: {
          severity: { enum: ['blocking', 'suggestion', 'nit'] },
          path: { type: 'string' },        // repo-relative
          line: { type: 'integer' },        // NEW-file line number (the + side)
          claim: { type: 'string' },
          why: { type: 'string' },
          fix: { type: 'string' },
          dependsOn: {                      // optional: other code the bug's control flow runs through, so the
            type: 'array',                  // verifier follows the same chain instead of rediscovering it cold.
            items: { type: 'string' },      // e.g. "src/session.rs:expire" — path, or path:symbol
          },
        },
      },
    },
  },
}

// One verifier handles every finding on a single file, so the verdict comes back as an array
// keyed by the finding's index in that file's batch.
const BATCH_VERDICT_SCHEMA = {
  type: 'object',
  required: ['verdicts'],
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        required: ['index', 'real', 'severity', 'reason'],
        properties: {
          index: { type: 'integer' },             // matches the [n] label in the prompt
          real: { type: 'boolean' },              // false = doesn't exist / already handled / misreads control flow / speculative
          severity: { enum: ['blocking', 'suggestion', 'nit'] },   // corrected; reviewer labels run hot
          reason: { type: 'string' },
        },
      },
    },
  },
}

function reviewPrompt(d) {
  return `You are reviewing a GitHub PR as a ${d.key} specialist.

PR intent: ${args.prIntent}

Unified diff (cite NEW-file line numbers — the + side):
${args.diff}

A read-only checkout at the PR head is at: ${args.worktreePath}
Read/Grep/Glob there to follow callers, imports, and context the diff doesn't show. That
checkout is the source of truth — do not assume anything about code you haven't opened.

Focus: ${d.rubric}

Return findings. Each must point to a specific NEW-file line the diff adds or changes.
If a bug only holds because of how code elsewhere behaves — the cited line is wrong only
given some other function's contract, a caller's assumption, a value set two files over — list
those places in \`dependsOn\` (e.g. "src/session.rs:expire"). That's the call-graph context you
traced to find it; recording it lets the verifier follow the same chain instead of starting cold.
No findings is a valid, common answer — do not invent nits to look thorough.`
}

function refuteBatchPrompt(path, findings, patch) {
  const list = findings
    .map((f, i) => {
      const dep = f.dependsOn?.length ? `\n    reviewer says the bug also runs through: ${f.dependsOn.join(', ')}` : ''
      return `[${i}] (${f.severity}) line ${f.line} — ${f.claim}\n    reviewer's reasoning: ${f.why}${dep}`
    })
    .join('\n\n')
  return `Adversarially verify code-review findings against the actual code. Your job is to
REFUTE each one. Default to real=false unless you can independently confirm the problem.

Every finding below is about the SAME file: ${path}
Open it ONCE at the PR head checkout (${args.worktreePath}/${path}), plus the callers and
callees the claims depend on, then judge all of them. Don't re-open the file per finding.

A bug's control flow can cross files — the cited line may be wrong only because of how code
elsewhere behaves. Where a finding lists what it "runs through", READ those too before judging;
many real bugs are invisible from the one file. Treat that list as a pointer, not proof — the
reviewer may be wrong about the dependency itself, so confirm the chain rather than assuming it.

Findings:
${list}

For each finding, by its [index], set:
- real: false if the cited line doesn't exist at head, the code already handles the case, the
  claim misreads control flow, or it's speculative. true ONLY on independent confirmation.
  Judge each finding on its own merits — don't let one weak claim taint the others.
- severity: your corrected severity (reviewer labels run hot).
- reason: one line.

This file's diff hunks, for context on what the PR changed here:
${patch}`
}

function mergeFindings(a, b) {
  const rank = { blocking: 3, suggestion: 2, nit: 1 }
  const hi = rank[b.severity] >= rank[a.severity] ? b : a
  const lo = hi === a ? b : a
  // Same line can host two genuinely distinct problems (e.g. a panic AND a wrong type on the
  // same call). Keep the higher-severity finding as the base, but fold in the other's claim,
  // why, and fix so nothing is silently dropped — the old `...hi` discarded lo.claim/lo.fix.
  // inDiff: if EITHER can attach inline, the merged comment can — never demote to body-only
  // just because the higher-severity finding happened to sit outside the diff.
  const inDiff = hi.inDiff || lo.inDiff
  if (a.claim === b.claim) {
    return { ...hi, inDiff, why: a.why === b.why ? a.why : `${a.why}\n\nAlso: ${b.why}` }
  }
  return {
    ...hi,
    inDiff,
    claim: `${hi.claim}\n\nAlso (${lo.severity}): ${lo.claim}`,
    why: `${hi.why}\n\nAlso: ${lo.why}`,
    fix: hi.fix === lo.fix ? hi.fix : `${hi.fix}\n\nFor the second: ${lo.fix}`,
  }
}

// inDiff is a deterministic fact, not a judgment: parse the unified diff ONCE to learn which
// NEW-file lines each file adds/changes, and to slice each file's own patch out of the whole.
// The verifier then skips judging inDiff (we compute it here, more reliably) and receives only
// its file's hunks instead of the entire PR diff — the verify phase's dominant token cost.
// Limitation: assumes plain `gh pr diff` output (no combined `@@@` diffs, no space-quoted
// paths). On any parse miss inDiff falls to false and the finding routes to the body — safe.
function parseDiff(diff) {
  const addedLines = {}   // path -> Set<new-file line number the PR adds/changes>
  const patches = {}      // path -> that file's slice of the unified diff
  let path = null, newLineNo = 0, inHunk = false, buf = []
  const flush = () => { if (path && buf.length) patches[path] = buf.join('\n') }
  for (const line of (diff ?? '').split('\n')) {
    if (line.startsWith('diff --git ')) { flush(); path = null; inHunk = false; buf = [line]; continue }
    buf.push(line)
    if (!inHunk && line.startsWith('+++ ')) {
      // header (not added content): +++ only precedes the first @@; inside a hunk it's a +line
      const p = line.slice(4).trim()
      path = p === '/dev/null' ? null : p.replace(/^b\//, '')
      if (path) addedLines[path] ??= new Set()
    } else if (line.startsWith('@@')) {
      inHunk = true
      const m = line.match(/\+(\d+)/)   // @@ -a,b +c,d @@  ->  c = first new-side line
      newLineNo = m ? parseInt(m[1], 10) : 0
    } else if (inHunk && path) {
      if (line.startsWith('+')) addedLines[path].add(newLineNo++)
      else if (line.startsWith('-') || line.startsWith('\\')) { /* removed / "No newline" — new side doesn't advance */ }
      else newLineNo++   // context line
    }
  }
  flush()
  return { addedLines, patches }
}
const { addedLines, patches } = parseDiff(args.diff)

// Output-token spend tracking, for the optional hard cap and live cost visibility.
const spentNow = () => (typeof budget !== 'undefined' && budget ? budget.spent() : 0)
const cap = args.budgetTokens || Infinity
const startSpent = spentNow()

// Reviewers fan out in parallel — each gets the full diff. (Benchmarked routing each reviewer
// only its own files' hunks to cut tokens; it didn't. The diff is ~7% of a reviewer's cost — the
// source files it reads from the worktree dominate — and a narrower slice just induced MORE
// reads. Agent count is the lever, not prompt size: fewer dimensions + the per-file verify batch
// below are what actually save.)
const reviews = await parallel(
  args.dimensions.map((d) => () =>
    agent(reviewPrompt(d), {
      label: `review:${d.key}`,
      phase: 'Review',
      schema: FINDINGS_SCHEMA,
      agentType: d.agentType,    // specialist when one exists; main loop passes undefined otherwise
    }),
  ),
)
const found = reviews.filter(Boolean).flatMap((r) => r.findings ?? [])
log(`review: ${found.length} findings across ${args.dimensions.length} dimensions, ${Math.round((spentNow() - startSpent) / 1000)}k output tokens`)

// Hard cap backstop. If the review phase alone exceeded the ceiling, don't spawn verifiers —
// return the findings UNVERIFIED so the main loop routes them to the body with a caveat rather
// than posting unconfirmed claims inline. Loud and safe beats a silent runaway.
if (spentNow() - startSpent > cap) {
  log(`BUDGET CAP HIT after review (${Math.round((spentNow() - startSpent) / 1000)}k > ${Math.round(cap / 1000)}k) — skipping verify, returning ${found.length} unverified findings`)
  return {
    findings: found.map((f) => ({
      severity: f.severity, path: f.path, line: f.line, claim: f.claim, why: f.why, fix: f.fix,
      inDiff: addedLines[f.path]?.has(f.line) ?? false,
      unverified: true,
    })),
    dropped: 0,
    droppedReasons: [],
    budgetHit: true,
  }
}

// Group by file, then one independent skeptic per file — NOT the specialist that raised the
// findings (that agent is biased to confirm its own work). A single adversarial pass: stacking
// more refuters behind a confirm-majority gate only drops more real findings, since each
// defaults to real=false.
const byPath = {}
for (const f of found) (byPath[f.path] ??= []).push(f)

const verified = await parallel(
  Object.entries(byPath).map(([path, fs]) => () =>
    agent(refuteBatchPrompt(path, fs, patches[path] ?? ''), { label: `verify:${path}`, phase: 'Verify', schema: BATCH_VERDICT_SCHEMA }).then((res) => {
      const verdicts = res?.verdicts ?? []
      return fs.map((f, i) => ({
        ...f,
        verdict: verdicts.find((v) => v.index === i) ?? { real: false, severity: f.severity, reason: 'verifier failed' },
      }))
    }),
  ),
)

const all = verified.filter(Boolean).flat()
const survived = all
  .filter((f) => f.verdict?.real)
  .map((f) => ({
    severity: f.verdict.severity ?? f.severity,
    path: f.path,
    line: f.line,
    claim: f.claim,
    why: f.why,
    fix: f.fix,
    inDiff: addedLines[f.path]?.has(f.line) ?? false,   // deterministic: is the cited NEW-file line one the PR added?
  }))

// Dedupe by path:line — mechanical, no agent. Keep the higher severity, fold in distinct reasons.
const byLine = {}
for (const f of survived) {
  const k = `${f.path}:${f.line}`
  byLine[k] = byLine[k] ? mergeFindings(byLine[k], f) : f
}

log(`total: ${Object.values(byLine).length} findings kept, ${all.length - survived.length} refuted, ${Math.round((spentNow() - startSpent) / 1000)}k output tokens`)
return {
  findings: Object.values(byLine),
  dropped: all.length - survived.length,
  droppedReasons: all
    .filter((f) => !f.verdict?.real)
    .map((f) => ({ path: f.path, line: f.line, why: f.verdict?.reason ?? 'unverified' })),
  budgetHit: false,
}
