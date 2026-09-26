### How to Delete Git Worktrees Safely

Deleting a worktree is simple, but you must follow the rules or you risk leaving stale entries or losing uncommitted work.

### Basic commands

| Command                                      | What it does                                                                 | When to use |
|----------------------------------------------|------------------------------------------------------------------------------|-------------|
| `git worktree remove <path>`                 | Clean removal (requires the worktree to be clean, i.e. no uncommitted changes) | Normal case |
| `git worktree remove --force <path>`         | Deletes even if there are uncommitted changes (dangerous — data loss possible) | You are 100% sure you don’t need the changes |
| `git worktree remove <branch-name>`          | You can use the branch name instead of the path (Git figures out the path)    | Convenient when you forgot the folder name |

### Step-by-step examples

```bash
# 1. List all worktrees first (always do this!)
git worktree list
# /path/to/main              abc1234 [main]
# /path/to/feature-login      def5678 [feature/login]
# /path/to/hotfix-123         9ab cdef [hotfix-123]

# 2. Normal clean removal
git worktree remove ../myproject-feature-login
# or
git worktree remove feature/login

# 3. If you have uncommitted changes and you’re sure you want to throw them away
git worktree remove --force ../myproject-feature-login

# 4. Remove multiple at once (Git ≥ 2.24)
git worktree remove ../old-feature-a ../old-feature-b --force
```

### What Git actually deletes

- The entire directory you pointed to (including your source files)
- The entry inside `.git/worktrees/<name>/` in the main repository

### Important rules & gotchas

| Situation                                      | What happens                                                                 | Correct action |
|------------------------------------------------|------------------------------------------------------------------------------|----------------|
| You manually `rm -rf` the worktree folder     | Directory is gone, but Git still thinks it exists                            | Run `git worktree prune` |
| The worktree is the main one (original repo)   | `git worktree remove` refuses                                                | Just delete the folder normally if you want |
| You have untracked files (not in Git)          | `git worktree remove` without `--force` still refuses                        | Use `--force` or clean them yourself first |
| Disk is full / permission issue                | Removal can fail and leave a half-deleted worktree                           | Run `git worktree prune` afterward |

### Cleanup command: `git worktree prune`

Run this periodically (or after manual deletions):

```bash
git worktree prune
# Removes references to worktrees whose directories no longer exist
# Also cleans up stale locks, etc.
```

Add `--verbose` to see what it’s doing, and `--dry-run` to preview.

### Safe workflow for deleting many old worktrees

```bash
# 1. See everything
git worktree list

# 2. Remove the ones you want (example)
git worktree remove feature/old-ui --force
git worktree remove feature/experiment-xyz --force
git worktree remove hotfix/may-2025 --force

# 3. Clean up any stragglers (manual deletions, crashes, etc.)
git worktree prune --verbose
```

### One-liner to nuke everything except the main worktree

```bash
git worktree list | grep -v '(bare)' | tail -n +2 | awk '{print $1}' | xargs -r git worktree remove --force
# Be extremely careful — this deletes ALL additional worktrees!
```

### Summary checklist before deleting

- Did I push/commit anything important?  
- Is this definitely not the main worktree?  
- Do I need `--force` because of uncommitted changes?  
- After manual deletion → run `git worktree prune`

That’s it — deleting worktrees is safe and fast once you know these commands.

Got a bunch of old worktrees cluttering your drive right now? Paste the output of `git worktree list` and I’ll tell you exactly which commands to run! 🧹

###### Tags : [[0 - Git 🍋‍🟩]]