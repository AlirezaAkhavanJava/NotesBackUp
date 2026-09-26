
Here are the main ways to undo changes in Git, depending on what you want to undo:

## 1. Undo changes in working directory (not staged)

**Discard changes to a specific file:**
```bash
git checkout -- <file>
# or (newer syntax)
git restore <file>
```

**Discard all unstaged changes:**
```bash
git checkout -- .
# or
git restore .
```

## 2. Unstage changes (keep the edits)

**Unstage a specific file:**
```bash
git restore --staged <file>
# or (older syntax)
git reset HEAD <file>
```

**Unstage everything:**
```bash
git restore --staged .
# or
git reset
```

## 3. Undo the last commit

**Keep changes staged (soft reset):**
```bash
git reset --soft HEAD~1
```

**Keep changes but unstaged (mixed reset - default):**
```bash
git reset HEAD~1
```

**Discard the commit and its changes entirely (hard reset):**
```bash
git reset --hard HEAD~1
```

## 4. Undo a commit that's already pushed

Use `git revert` — it creates a new commit that reverses the changes (safe for shared branches):
```bash
git revert <commit-hash>
```

## 5. Undo to a specific commit

```bash
git reset --hard <commit-hash>
```

## 6. Recover "lost" commits after a hard reset

```bash
git reflog
# find the commit hash you want
git reset --hard <hash>
```

## Quick reference

| Goal | Command |
|------|---------|
| Discard file edits | `git restore <file>` |
| Unstage a file | `git restore --staged <file>` |
| Undo last commit (keep changes) | `git reset --soft HEAD~1` |
| Undo last commit (discard changes) | `git reset --hard HEAD~1` |
| Undo pushed commit | `git revert <hash>` |
| Recover lost commit | `git reflog` then `git reset --hard <hash>` |

**⚠️ Warning:** `--hard` is destructive — you'll lose uncommitted work. When in doubt, use `git reflog` first to make sure you can recover.


---
# Git Reset

`git reset` is a command that moves the **HEAD** (and optionally the branch pointer) to a different commit, and can also modify the **staging area** and **working directory**. It's primarily used to undo commits, unstage changes, or discard work.

## The Three Trees of Git

To understand `reset`, you need to know Git's three internal states:

| Tree | What it is |
|------|-----------|
| **HEAD** | The last commit on your current branch (the committed snapshot) |
| **Index (Staging Area)** | What will go into your next commit |
| **Working Directory** | The actual files on your disk |

`git reset` moves these around depending on which **mode** you use.

## The Three Modes

### `--soft`
Moves **HEAD** only. Leaves the index and working directory untouched.

```bash
git reset --soft HEAD~1
```
- Undoes the commit
- Changes stay **staged** and ready to re-commit
- Use when: you want to redo a commit (change message, combine commits, etc.)

### `--mixed` (default)
Moves **HEAD** and resets the **index**. Leaves working directory untouched.

```bash
git reset HEAD~1
# same as
git reset --mixed HEAD~1
```
- Undoes the commit
- Changes stay in working directory but become **unstaged**
- Use when: you want to unstage changes or re-select what to commit

### `--hard`
Moves **HEAD**, resets the **index**, and overwrites the **working directory**.

```bash
git reset --hard HEAD~1
```
- Undoes the commit
- **Permanently discards** all changes
- Use when: you want to completely throw away work
- ⚠️ **Dangerous** — uncommitted changes are lost (though committed ones can be recovered via `git reflog`)

## Visual Comparison

```
                  HEAD    Index    Working Dir
--soft            ✓       ✗        ✗
--mixed (default) ✓       ✓        ✗
--hard            ✓       ✓        ✓
```
(✓ = reset/moved, ✗ = left alone)

## Common Forms

```bash
git reset HEAD~1              # undo last commit, unstage changes
git reset HEAD~3              # undo last 3 commits
git reset <file>              # unstage a file (mixed)
git reset <commit-hash>       # move HEAD to a specific commit
git reset --hard origin/main  # match remote exactly (discard local work)
```

## Key Points

- **Only affects your local repo** — never rewrite already-pushed history with `reset` on shared branches (use `revert` instead).
- **`reset` vs `revert`**: `reset` moves history backward; `revert` creates a new commit that undoes a previous one.
- **Recoverable**: Even after `--hard`, committed work can usually be found via `git reflog`.
- **HEAD~1** means "one commit before HEAD." You can also use a commit hash.

In short: **`git reset` repositions your branch to an earlier point and decides how much of your staged/unstaged work to keep or discard.**



[[0 - Git 🍋‍🟩]]