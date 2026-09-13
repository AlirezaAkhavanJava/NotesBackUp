`upstream` is **not a built-in Git remote** — it's a **common convention** for naming a remote repository that points to the **original project** (the one you forked from).

---

### What is `upstream`?

| Term | Meaning |
|------|--------|
| `origin` | Your **fork** (your copy on GitHub/GitLab/etc.) — where you push your changes |
| `upstream` | The **original repository** you forked from — read-only for you, used to pull updates |

---

### Typical Workflow (GitHub Example)

```bash
# 1. You forked https://github.com/torvalds/linux → your fork: https://github.com/yourname/linux
# 2. You cloned your fork:
git clone https://github.com/yourname/linux.git
cd linux

# By default, only `origin` exists:
git remote -v
# → origin  https://github.com/yourname/linux.git (fetch/push)
```

---

### Add `upstream` to sync with the original repo

```bash
git remote add upstream https://github.com/torvalds/linux.git
```

Now:
```bash
git remote -v
```
```
origin    https://github.com/yourname/linux.git (fetch)
origin    https://github.com/yourname/linux.git (push)
upstream  https://github.com/torvalds/linux.git (fetch)
upstream  https://github.com/torvalds/linux.git (push)
```

---

### Use `upstream` to Stay Updated

```bash
# Fetch latest changes from upstream
git fetch upstream

# Merge into your local main branch
git checkout main
git merge upstream/main

# Push updated main to your fork (origin)
git push origin main
```

---

### Pro Tip: Sync a Fork (One-Liner)

```bash
git fetch upstream && git checkout main && git merge upstream/main && git push
```

---

### Verify or Fix `upstream`

```bash
# Check if upstream exists
git remote show upstream

# If missing, add it
git remote add upstream <original-repo-url>

# If wrong URL, fix it
git remote set-url upstream https://github.com/original/repo.git
```

---

### Summary

| Remote | URL | Purpose |
|-------|-----|--------|
| `origin` | `https://github.com/yourname/repo.git` | Your fork — **push here** |
| `upstream` | `https://github.com/original/repo.git` | Original repo — **pull updates from here** |

---


##### Tags : [[0 - Git 🍋‍🟩]]