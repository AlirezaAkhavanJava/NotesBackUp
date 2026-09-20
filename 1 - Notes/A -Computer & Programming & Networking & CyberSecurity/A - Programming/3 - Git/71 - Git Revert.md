
### What is `git revert`?

`git revert` is the safest and most common way to **undo** a commit that has already been pushed to a shared repository (e.g., origin/main).

Instead of rewriting history (like `git reset` does), `git revert` creates a **new commit** that applies the inverse changes of the commit(s) you want to undo. This keeps the history linear and doesn’t cause problems for other collaborators.

### Basic Syntax

```bash
git revert <commit-hash>
```

Examples:

```bash
# Revert a single commit
git revert a1b2c3d

# Revert multiple commits (in order)
git revert a1b2c3d b2c3d4e f5g6h7i

# Revert a merge commit (you’ll be asked which parent to revert relative to)
git revert -m 1 <merge-commit-hash>
```

### Common Options

| Option              | Meaning                                                                 | Example                          |
|---------------------|-------------------------------------------------------------------------|----------------------------------|
| `-m 1`              | For merge commits: revert relative to the first (mainline) parent      | `git revert -m 1 abc123`         |
| `--no-edit`         | Don’t open the editor for the commit message                            | `git revert --no-edit abc123`    |
| `-n` or `--no-commit` | Apply the revert changes but don’t create the commit automatically   | `git revert -n abc123`           |
| `--continue`        | After resolving conflicts, finish the revert                           | `git revert --continue`          |
| `--abort`           | Cancel the entire revert operation                                      | `git revert --abort`             |
| `--quit`            | Stop the revert but keep the changes staged                            | `git revert --quit`              |

### Typical Workflow Examples

1. **Undo the most recent commit (that was already pushed)**
   ```bash
   git revert HEAD
   git push origin main
   ```

2. **Undo an older commit**
   ```bash
   git revert 3f2a1b4
   git push
   ```

3. **Undo a range of commits (newer to older)**
   ```bash
   git revert old-commit..new-commit   # Note: this reverts commits from old to new
   # Better: list them explicitly in chronological order (oldest first)
   git revert abc123 def456 ghi789
   ```

4. **Undo a merge commit**
   ```bash
   git revert -m 1 abc1234   # -m 1 usually means "keep the main branch changes"
   ```

5. **Revert but inspect/modify changes first**
   ```bash
   git revert --no-commit abc123
   # make any additional changes
   git commit
   ```

### How `git revert` Actually Works (Internally)

If the original commit added the lines:

```diff
+ Hello world
+ This is a new feature
```

`git revert` will create a new commit with:

```diff
- Hello world
- This is a new feature
```

So the net effect is that those changes are undone, but the history still shows both the original commit and the revert.

### `git revert` vs `git reset` vs `git restore`

| Command             | Rewrites history? | Safe for shared branches? | Use case                                      |
|---------------------|-------------------|---------------------------|-----------------------------------------------|
| `git revert`        | No                | Yes                       | Undoing commits already pushed to shared repo |
| `git reset --hard`  | Yes               | No (dangerous)            | Local history cleanup, never on shared branch |
| `git restore`       | No                | Yes                       | Undo uncommitted changes in working tree      |

### Quick Cheat Sheet

```bash
# Simple revert
git revert <sha>

# Revert without opening editor
git revert --no-edit <sha>

# Revert merge commit
git revert -m 1 <merge-sha>

# Revert and keep changes staged (for tweaking)
git revert -n <sha>
# edit files if needed
git commit -m "Revert ... with adjustments"
```

That’s pretty much everything you need for day-to-day use of `git revert`. Let me know if you have a specific scenario (like reverting a merge, a range, or dealing with conflicts) and I can walk you through it!
###### Tags : [[0 - Git 🍋‍🟩]]