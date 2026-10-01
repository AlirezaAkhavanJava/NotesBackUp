

## Before Opening an Issue

**When to open one first:** anything beyond a trivial typo/one-line fix — new features, non-trivial bug fixes, anything touching multiple files or changing behavior. Confirm the maintainer wants it before you invest real effort.

**Before opening it:**

1. Search existing issues (open **and** closed) — your bug/idea might already be known or rejected with reasons
2. Reproduce the bug with exact, minimal steps — "it doesn't work" gets ignored, "doing X with Y produces Z, expected W" gets fixed
3. Rule out your own setup (wrong version, misconfiguration) before blaming the project

**Good issue template:**

```markdown
**Describe the problem**
[Clear, specific]

**To Reproduce** (for bugs)
1. Exact steps

**Expected behavior**
[What should happen]

**Would a PR be welcome if I built this?**
```

That last line is the key habit — signal you're willing to do the work, and ask before building it.

---

## Before Hitting "Create Pull Request"

1. **Sync your fork first** — `git fetch upstream && git merge upstream/main && git push origin main`
2. **Branch off the freshly-synced main** — one focused branch per logical change
3. **Keep it small and single-purpose** — never bundle an unrelated fix into the same PR
4. **Match existing code style** exactly — not your personal preferences
5. **Run tests/linter locally** before pushing — a PR that breaks CI immediately looks careless
6. **Review your own diff critically** before pushing:
    
    ```bash
    git diff upstream/main...your-branch
    ```
    
    Check for: debug statements left in, commented-out code, accidental files (`.idea/`, `target/`), unrelated formatting noise
7. **Clean up commit history** if it's messy (`git rebase -i upstream/main`) — squash "wip" commits into logical ones
8. **Push to your fork**, not upstream: `git push -u origin your-branch`

---

## Writing the PR Itself

```markdown
## What this does
[One or two sentences]

## Why
Fixes #42   ← auto-closes the linked issue on merge

## How I tested this
[What you ran/verified]
```

---

## After Opening

|Situation|Action|
|---|---|
|CI fails|Fix, commit, push to the same branch|
|Reviewer requests changes|Push more commits — don't open a new PR|
|Asked to squash|`rebase -i`, then `push --force-with-lease`|
|Upstream moved while PR open|`fetch upstream && rebase upstream/main`, resolve conflicts, `push --force-with-lease`|

---

**One-line summary:**

> Issue first for anything non-trivial (confirm the approach before building it), then keep the PR small, tested, synced with upstream, and clearly described — every step is about making it easy for the maintainer to trust and merge your change with minimal effort on their end.


[[0 - Git]]