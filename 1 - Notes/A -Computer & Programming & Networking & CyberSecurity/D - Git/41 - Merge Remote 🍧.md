`git merge remote` is **invalid syntax** — but you **can** merge a **remote branch** into your current branch.

---

## Correct Way: `git merge <remote>/<branch>`

```bash
git merge origin/main
git merge upstream/main
```

---

## Step-by-Step: Merge Remote Branch

### 1. **Fetch latest from remote**
```bash
git fetch upstream
```
> Always fetch first — ensures you have the latest.

---

### 2. **Switch to your local branch**
```bash
git checkout main
```

---

### 3. **Merge the remote branch**
```bash
git merge upstream/main
```

> This brings `upstream/main` changes into your `main`.

---

### 4. **Push to your fork**
```bash
git push origin main
```

---

## Full One-Liner (Sync Fork)

```bash
git fetch upstream && git checkout main && git merge upstream/main && git push origin main
```

---

## What Happens During Merge?

| Situation | Result |
|--------|--------|
| No conflicts | Fast-forward or merge commit |
| Conflicts | Git pauses — you fix manually |

---

## Check Before Merging (Recommended)

```bash
# See what will be merged
git log --oneline HEAD..upstream/main

# Or full diff
git diff HEAD upstream/main
```

---

## Common Merge Commands

| Command | Use |
|-------|-----|
| `git merge upstream/main` | Merge into current branch |
| `git merge --no-ff upstream/main` | Force a merge commit (even if fast-forward) |
| `git merge --abort` | Cancel merge on conflict |
| `git merge --continue` | After fixing conflicts |

---

## Pro Example: Safe Merge

```bash
git fetch upstream
git checkout main

# Preview changes
git log --oneline --graph HEAD..upstream/main

# Merge
git merge upstream/main

# Push
git push origin main
```

---

## Invalid (Don’t Use)

```bash
git merge remote        # Invalid
git merge origin        # Invalid (origin is not a branch)
```

**Correct**:
```bash
git merge origin/main
git merge upstream/main
```

---

## Quick Reference Card

```bash
# 1. Update remote data
git fetch upstream

# 2. Merge into your branch
git checkout main
git merge upstream/main

# 3. Push to your fork
git push origin main
```

---

##### Tags : [[0 - Git 🍋‍🟩]]