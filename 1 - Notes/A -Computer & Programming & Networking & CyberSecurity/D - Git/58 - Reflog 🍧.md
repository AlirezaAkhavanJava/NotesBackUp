

## What is `git reflog`?

**`git reflog`** (reference log) is Git's safety net. It's a local history of **every action you've performed** in your repository - every commit, checkout, merge, rebase, and even actions that might have "lost" commits.

### The Simple Analogy

Think of `git reflog` as the **"undo history" or "command history"** of your repository. While `git log` shows you the commit history of your project, `git reflog` shows you the history of what **you did** in your repository.

## Why is `git reflog` So Important?

**It can recover "lost" work!** When you:
- Accidentally delete a branch
- Reset or rebase and lose commits
- Check out the wrong branch and lose your work
- Any other operation that makes you think "oh no, where did my code go?"

`git reflog` can usually save you.

## How to Use `git reflog`

### Basic Usage
```bash
git reflog
```

### Example Output
```
f45a2b1 (HEAD -> main) HEAD@{0}: commit: Fix login bug
a1b2c3d HEAD@{1}: checkout: moving from feature to main
d4e5f6a HEAD@{2}: commit: Add user authentication
7890abc HEAD@{3}: pull origin main
23456de HEAD@{4}: reset: moving to HEAD~1
```

## Understanding the Format

Each line shows:
- **Commit hash** (e.g., `f45a2b1`)
- **Reference** (e.g., `HEAD -> main`)
- **Position** (e.g., `HEAD@{0}` - most recent)
- **Action** that was performed

## Common Recovery Scenarios

### 1. Recover a Deleted Branch
```bash
# You accidentally: git branch -D my-feature
git reflog
# Find the commit where you deleted the branch
git checkout -b my-feature <commit-hash>
```

### 2. Undo a Hard Reset
```bash
# You accidentally: git reset --hard HEAD~3
git reflog
# Find the state before the reset
git reset --hard HEAD@{1}
```

### 3. Recover After a Bad Rebase
```bash
# Your rebase went wrong
git reflog
# Find the state before the rebase started
git reset --hard <pre-rebase-commit>
```

### 4. Find a "Lost" Commit
```bash
# You remember part of the commit message
git reflog --grep="login"
```

## Practical Examples

### Example 1: Accidentally Deleted Work
```bash
# Oops! You hard reset and lost work
git reset --hard HEAD~2

# Check reflog to see what you had
git reflog
# Output shows: 
# a1b2c3d HEAD@{0}: reset: moving to HEAD~2
# d4e5f6a HEAD@{1}: commit: Important feature work

# Recover it!
git checkout d4e5f6a
# Or create a new branch from that commit
git checkout -b recovered-work d4e5f6a
```

### Example 2: Find When You Merged
```bash
git reflog show --date=iso
# This shows timestamps for all actions
```

## Advanced `git reflog` Usage

### Show Specific Reference
```bash
git reflog show main      # History of main branch
git reflog show HEAD      # History of HEAD (default)
git reflog show feature   # History of feature branch
```

### With Dates and Filtering
```bash
git reflog --since="1 week ago"
git reflog --until="yesterday"
git reflog --grep="merge"
```

### Expire and Cleanup
```bash
# Reflog entries expire after 90 days by default
git reflog expire --expire=30.days
git gc --prune=now
```

## Important Characteristics of Reflog

- **Local only**: Each developer has their own reflog
- **Temporary**: Entries expire (default: 90 days)
- **Action-oriented**: Shows what you did, not just the commit history
- **Branch-specific**: Each branch has its own reflog

## Reflog vs Log

| `git log` | `git reflog` |
|-----------|--------------|
| Shows commit history | Shows action history |
| Project timeline | Your personal timeline |
| Shared history | Local-only history |
| Permanent record | Temporary record (90 days) |

## Pro Tips

1. **Check reflog first** when something goes wrong
2. **Use `HEAD@{n}` syntax** to reference positions
3. **Combine with `git show`** to inspect commits:
   ```bash
   git show HEAD@{2}
   ```
4. **It's your safety net** - don't be afraid to experiment!

## Summary

**`git reflog` is Git's undo history.** It remembers everything you've done, so even when you think you've lost work permanently, `git reflog` can usually help you recover it. It's one of the most valuable tools for recovering from mistakes in Git.
##### Tags : [[0 - Git 🍋‍🟩]]