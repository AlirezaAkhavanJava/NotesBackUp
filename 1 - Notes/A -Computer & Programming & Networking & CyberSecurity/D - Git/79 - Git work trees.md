
### What is `git worktree`?

`git worktree` (introduced in Git 2.5) lets you have **multiple working directories** attached to the **same repository**.  
Each worktree has its own checked-out branch, independent working files, index/staging area, but they all share the same `.git` objects, refs, and history.

Think of it as lightweight "clones" without duplicating the entire repo.

### Why use git worktree instead of just `git checkout`?

| Use Case                              | Without worktree                          | With worktree                                      |
|---------------------------------------|-------------------------------------------|----------------------------------------------------|
| Work on two branches at once          | Have to stash/commit constantly           | Two (or more) folders open side-by-side            |
| Long-running builds/tests on one branch | Blocks your terminal/repo                 | Keep working on another branch in another folder   |
| Disk space                           | `git clone` duplicates everything         | Shares the same `.git` directory → saves GBs       |
| Switch branches quickly               | `git checkout` wipes your working changes | No need to stash/commit, just `cd` to another tree |

### Basic commands

```bash
# List all worktrees
git worktree list

# Create a new worktree (checks out a new or existing branch)
git worktree add ../myproject-feature   feature/login
git worktree add ../myproject-hotfix    hotfix/bug-123

# You can also create a new branch at the same time
git worktree add ../myproject-new-ui    -b new-ui-branch

# Create a worktree in detached HEAD (rare)
git worktree add ../myproject-tag       v2.5.0

# Remove a worktree (must be clean or use -f)
git worktree remove ../myproject-hotfix
git worktree remove --force ../myproject-hotfix   # if dirty

# Prune stale worktree entries (e.g., after manual deletion)
git worktree prune
```

### Typical folder layout

```
myproject-main/          ← main worktree (the original one)
myproject-feature/       ← git worktree add ../myproject-feature feature/x
myproject-hotfix/        ← git worktree add ../myproject-hotfix  hotfix/y
myproject-experiment/    ← another one
```

All of them share the same `.git` directory inside `myproject-main/.git` (or bare repo if you use `--bare`).

### Real-world example: Parallel development

```bash
# You're on main, working on something
cd myproject

# Open a new terminal and start working on a feature without stashing
git worktree add ../myproject-login-feature feature/login

# Now you have:
# ~/myproject/             → on main
# ~/myproject-login-feature/ → on feature/login

# You can run tests, builds, etc., in both directories simultaneously
```

### Important rules & gotchas

| Rule                                    | Explanation                                                                 |
|-----------------------------------------|-----------------------------------------------------------------------------|
| One branch checked out in only ONE worktree at a time | You cannot have `main` checked out in two worktrees simultaneously          |
| `main` worktree is special              | The original directory is called the "main worktree". You can't remove it with `git worktree remove` |
| Deleting a worktree folder manually     | Use `git worktree prune` afterward to clean up the internal records        |
| `git gc` and other commands             | Run them from any worktree — they affect the shared repository             |
| Sparse-checkout works per worktree      | Each worktree can have its own sparse-checkout pattern                     |

### Advanced: Create worktree from bare repo

```bash
# On a server or for huge repos
git clone --bare https://github.com/user/repo.git repo.git

cd repo.git
git worktree add ../repo-main main
git worktree add ../repo-feature feature/x
```

Now you have a central bare repo with many working directories — super efficient.

### Pro tips

```bash
# Shortcut: add worktree and cd into it immediately
git worktree add -b new-branch ../repo-new-branch && cd ../repo-new-branch

# List with more details
git worktree list --porcelain

# Move a worktree to a new path
git worktree move old-path new-path
```

### When NOT to use worktree

- Simple personal projects where `git switch` + stash is enough.
- If your team/tools don’t understand multiple worktrees (rare nowadays).

### Summary

| Feature                        | `git clone`            | `git worktree`               |
|--------------------------------|------------------------|------------------------------|
| Disk usage                     | High (duplicates .git) | Low (shared .git)            |
| Checkout multiple branches     | Yes                    | Yes                          |
| Speed                          | Slower                 | Instant                      |
| Same repo history/refs         | Separate               | Shared                       |

`git worktree` is one of the most productivity-boosting Git features once you start using it — especially on big monorepos.

Try it now: open a terminal and run `git worktree add ../myproject-temp some-branch` — you’ll never go back to stashing again! 🚀


##### Tags : [[0 - Git 🍋‍🟩]]