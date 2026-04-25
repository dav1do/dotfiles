#!/usr/bin/env python3
"""
pr-review.py - Review a PR with Claude Code in an isolated worktree.

Usage:
    python pr-review.py 123
    python pr-review.py 123 --no-cleanup
"""

import argparse, json, os, subprocess, sys, tempfile


def sh(cmd, check=True):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if check and r.returncode != 0:
        sys.exit(f"FAILED: {' '.join(cmd)}\n{r.stderr}")
    return r.stdout.strip()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("pr", type=int)
    p.add_argument("--no-cleanup", action="store_true")
    args = p.parse_args()

    # PR metadata
    info = json.loads(
        sh(
            [
                "gh",
                "pr",
                "view",
                str(args.pr),
                "--json",
                "headRefName,baseRefName,title,url",
            ]
        )
    )
    head, base, title = info["headRefName"], info["baseRefName"], info["title"]
    print(f"PR #{args.pr}: {title}\n  {head} → {base}")

    # Worktree setup
    wt = os.path.join(tempfile.gettempdir(), f"claude-pr-{args.pr}")
    branch = f"pr-review-{args.pr}"

    if os.path.isdir(wt):
        sh(["git", "worktree", "remove", wt, "--force"])
    subprocess.run(["git", "branch", "-D", branch], capture_output=True)

    sh(["git", "fetch", "origin", f"pull/{args.pr}/head:{branch}"])
    sh(["git", "worktree", "add", wt, branch])
    print(f"  Worktree: {wt}")

    review_file = os.path.join(tempfile.gettempdir(), f"pr-review-body-{args.pr}.md")

    prompt = (
        f"You are reviewing PR #{args.pr}: {title}\n"
        f"URL: {info['url']}\n"
        f"Base: {base} | Head: {head}\n\n"
        f"Instructions:\n"
        f"1. Run `git diff {base}...HEAD` to see the full diff.\n"
        f"2. Do a thorough code review: check for bugs, logic errors, edge cases,\n"
        f"   style issues, missing error handling, security concerns, and test coverage.\n"
        f"3. Write your review in markdown to: {review_file}\n"
        f"   Format: start with a summary, then file-by-file findings with line refs.\n"
        f"4. Post it to GitHub:\n"
        f"   gh pr review {args.pr} --comment --body-file {review_file}\n"
    )

    try:
        subprocess.run(["claude", "-p", prompt], cwd=wt)
    finally:
        if not args.no_cleanup:
            sh(["git", "worktree", "remove", wt, "--force"])
            subprocess.run(["git", "branch", "-D", branch], capture_output=True)
            print("Cleaned up worktree.")


if __name__ == "__main__":
    main()
