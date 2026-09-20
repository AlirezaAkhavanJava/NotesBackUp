
`git pull` fetches changes from the **remote repository** and **merges** them into your current local branch.

---

### Basic Syntax
```bash
git pull <remote> <branch>
```

**Most common usage (if upstream is set):**
```bash
git pull
```
Automatically pulls from the tracked remote branch.

---

### Full Example
```bash
git pull origin main
```

---

### How It Works (Under the Hood)
`git pull` = `git fetch` + `git merge`

1. **`git fetch`** → Downloads commits, files, and refs from remote.
2. **`git merge`** → Merges the fetched branch into your current branch.

---

### Common Options

| Command | Purpose |
|--------|--------|
| `git pull --rebase` | Rebase your local commits on top of remote (cleaner history) |
| `git pull --no-commit` | Fetch + merge but don't auto-commit |
| `git pull -p` | Prune deleted remote branches |
| `git pull --ff-only` | Only allow fast-forward updates (safer) |

---

### Recommended: Use `--rebase` for cleaner history
```bash
git pull --rebase origin main
```
Your local commits are replayed **on top** of remote changes → no unnecessary merge commits.

> Tip: Set it globally:
> ```bash
> git config --global pull.rebase true
> ```

---

### Common Scenarios

#### 1. **You're behind remote**
```bash
git pull
# → Merges remote changes
```

#### 2. **You have local commits + remote has new ones**
```bash
git pull --rebase
# → Remote changes first, then your commits on top
```

#### 3. **Conflict during pull**
```bash
git pull
# → CONFLICT (content): Merge conflict in file.txt
```
**Fix:**
```bash
# Edit conflicting files
git add <resolved-files>
git rebase --continue   # if using --rebase
# OR
git commit              # if using merge
```

#### 4. **Just update (no merge)**
```bash
git fetch               # Safe: only downloads
git log HEAD..origin/main  # See what's new
git merge origin/main   # Then merge manually
```

---

### Best Practice Workflow
```bash
git fetch               # Always safe
git status              # See if you're behind/ahead
git pull --rebase       # Or just `git pull` if rebase is default
git push                # Now safe to push
```

---

### Common Errors & Fixes

| Error | Fix |
|------|-----|
| `fatal: No remote 'origin'` | Run `git remote add origin <url>` |
| `merge conflict` | Edit files, `git add .`, then `git rebase --continue` or `git commit` |
| `refusing to merge unrelated histories` | Use `git pull --allow-unrelated-histories` (rare) |
| `fatal: Need to specify how to reconcile divergent branches` | Set `git config pull.rebase true` or use `--rebase`/`--no-rebase` |

---

### Pro Tip: Always `fetch` before `pull`
```bash
git fetch
git status   # Shows: "Your branch is behind 'origin/main' by 3 commits"
```
Then decide: rebase, merge, or review first.

---





##### Tags : [[0 - Git 🍋‍🟩]]