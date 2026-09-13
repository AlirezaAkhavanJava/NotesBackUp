


| Feature | `git fetch` | `git pull` |
|--------|-------------|------------|
| **What it does** | **Downloads** new commits, branches, tags from remote | **Downloads + merges** into your current branch |
| **Changes your local files?** | No | Yes |
| **Safe to run anytime?** | Yes (read-only) | Only if you're ready to merge |
| **Under the hood** | `git fetch` only | `git fetch` **+** `git merge` (or rebase) |
| **Affects working directory?** | Never | Yes (unless conflicts) |
| **Can cause merge conflicts?** | No | Yes |
| **Recommended for daily use** | **Yes** (safer) | Use carefully |

---

### Visual Example

```bash
# Remote has 3 new commits: A — B — C
# Your local branch is at:   X — Y
```

#### After `git fetch`:
```
Remote:        A — B — C
Local:   X — Y
               ↑
           (origin/main points here)
```
> Your files **unchanged**, but you **know** what’s new.

#### After `git pull`:
```
Local:   X — Y — A — B — C   (merged)
```
> Your branch is updated and files are changed.

---

### When to Use Which?

| Use Case | Command |
|--------|---------|
| Check what’s new on remote | `git fetch` |
| See who’s ahead/behind | `git status` after fetch |
| Update your branch **safely** | `git fetch` → review → `git merge` or `git rebase` |
| Quickly sync and merge | `git pull` |
| Avoid surprises | `git fetch` |
| Clean linear history | `git pull --rebase` |

---

### Best Practice Workflow

```bash
git fetch                   # 1. Always safe — just download
git status                  # 2. See: "behind by 3 commits"
git log HEAD..origin/main   # 3. Preview incoming changes
git pull --rebase           # 4. Now update (or merge manually)
```

---

### Pro Tip: Make `pull` = `fetch + rebase`

```bash
git config --global pull.rebase true
```
Now `git pull` will **never create merge commits** — cleaner history!

---

### TL;DR

> **`fetch`** = **"Download updates"**  
> **`pull`** = **"Download + apply updates"**

**Always `fetch` first. `pull` when you're ready.**

---


##### Tags : [[0 - Git 🍋‍🟩]]