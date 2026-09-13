
> `git fetch` **downloads** commits, files, and refs from a remote repository into your local repo — **without merging** them into your current branch.

---

### Basic Syntax
```bash
git fetch <remote>
```

- Default remote: `origin`
- Common remotes: `origin`, `upstream`

---

## Key Differences

| Command | What it does |
|--------|--------------|
| `git fetch` | **Downloads** new data from remote (safe) |
| `git pull`  | `fetch` + `merge` (can change your files) |

> **Use `fetch` when you want to *see* updates before merging.**

---

## Common Usage

### 1. Fetch from `origin` (your fork)
```bash
git fetch origin
```

### 2. Fetch from `upstream` (original repo)
```bash
git fetch upstream
```

### 3. Fetch **all** remotes
```bash
git fetch --all
```

---

## Typical Workflow (Syncing a Fork)

```bash
# 1. Fetch latest from original repo
git fetch upstream

# 2. Switch to your main branch
git checkout main

# 3. Merge upstream changes
git merge upstream/main

# 4. Push updated code to your fork
git push origin main
```

---

## What `git fetch` Downloads

After `git fetch upstream`:
```
remote/upstream/main  →  origin/main (but not merged yet)
remote/upstream/dev   →  new branches appear locally as:
    upstream/main
    upstream/dev
```

You can now:
```bash
git log upstream/main        # See new commits
git diff main..upstream/main # Compare changes
git merge upstream/main      # Apply them
```

---

## Useful Options

| Command | Purpose |
|-------|--------|
| `git fetch --dry-run` | See what *would* be fetched |
| `git fetch --prune` | Remove local tracking branches for deleted remote branches |
| `git fetch -p` | Short for `--prune` |

```bash
git fetch --prune origin
# or
git fetch -p
```

---

## Check What Was Fetched

```bash
git log HEAD..upstream/main --oneline
```
→ Shows commits in `upstream/main` that you don’t have yet.

---

## Pro Tip: Always Fetch Before Push

```bash
git fetch origin
git status
# → "Your branch is behind 'origin/main' by 3 commits"
```

Avoids conflicts and rejected pushes.

---

## One-Liner: Safe Sync from Upstream

```bash
git fetch upstream && git checkout main && git merge upstream/main && git push
```

---

## Summary Table

| Command | Safe? | Merges? | Use Case |
|--------|-------|--------|---------|
| `git fetch` | Yes | No | Preview updates |
| `git pull`  | Risky | Yes | Quick update (if clean) |

---


##### Tags : [[0 - Git 🍋‍🟩]]