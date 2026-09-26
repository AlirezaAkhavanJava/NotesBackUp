


`git fetch` **downloads commits, branches, and tags from a remote** into your local repository — but **does not merge or modify your working files**. It updates your *remote-tracking branches* only.

## Basic Syntax

```bash
git fetch <remote>
git fetch <remote> <branch>
git fetch --all
```

## What It Actually Does

```
Remote repo (GitHub)
      │
      │  git fetch  ↓ downloads
      ▼
Remote-tracking branches (origin/main, upstream/main)   ← updated
      │
      │  (nothing automatic)
      ▼
Your local branch (main)                                ← unchanged
Working directory                                       ← unchanged
```

**Key point:** `fetch` is **safe** — it never touches your working directory or your local branches. It just updates the "snapshot" Git keeps of the remote.

## Common Examples

```bash
git fetch origin              # fetch from origin
git fetch upstream            # fetch from upstream
git fetch --all               # fetch from ALL remotes
git fetch origin main         # fetch only main from origin
git fetch --prune             # also delete stale remote-tracking branches
```

## fetch vs pull

| | `git fetch` | `git pull` |
|---|------------|-----------|
| Downloads from remote | ✅ | ✅ |
| Updates remote-tracking branches | ✅ | ✅ |
| Merges into your local branch | ❌ | ✅ |
| Modifies working directory | ❌ | ✅ |
| Safe? | Always safe | Can cause conflicts |

> `git pull` = `git fetch` + `git merge` (or `git rebase` if configured)

**Best practice:** `fetch` first, review changes, then merge/rebase manually:
```bash
git fetch origin
git log HEAD..origin/main      # see what's new
git merge origin/main          # or: git rebase origin/main
```

## After Fetching — Using the Updates

Fetch updates `origin/main`, but your local `main` is still old. To integrate:

```bash
git checkout main
git merge origin/main          # bring fetched changes into local main
# or
git rebase origin/main         # replay your commits on top
```

Or inspect before merging:
```bash
git diff main origin/main      # what changed
git log main..origin/main      # new commits
```

## Useful Options

| Option | Effect |
|--------|--------|
| `--all` | Fetch from every remote |
| `--prune` | Remove remote-tracking branches deleted on the remote |
| `--prune --all` | Prune across all remotes |
| `--tags` | Also fetch tags |
| `--depth=1` | Shallow fetch (just latest commit) |
| `-v` | Verbose output |
| `--dry-run` | Show what would happen without doing it |

## Cleaning Up Stale Branches

When a branch is deleted on the remote, your local `origin/xxx` reference lingers. Clean it up:

```bash
git fetch --prune
# or set it permanently:
git config --global fetch.prune true
```

## Remote-Tracking Branches Explained

After `git fetch origin`, Git updates refs like:

```
refs/remotes/origin/main
refs/remotes/origin/feature-x
```

These are **read-only snapshots** of the remote's state. You can:
- View them: `git log origin/main`
- Branch off them: `git checkout -b mybranch origin/main`
- Merge them: `git merge origin/main`
- **Not** commit to them directly

## Recovering After a Fetch

Nothing to recover — `fetch` is non-destructive. It only adds/updates remote-tracking refs.

## Summary

- `git fetch` = **download remote changes, don't apply them**
- Safe to run anytime — never overwrites your work
- Updates `origin/*` and `upstream/*` branches, not your local branches
- Use `git fetch --prune` to clean up deleted branches
- Follow with `merge` or `rebase` to integrate the changes into your work
- `git pull` = `fetch` + `merge` in one step



[[0 - Git 🍋‍🟩]]