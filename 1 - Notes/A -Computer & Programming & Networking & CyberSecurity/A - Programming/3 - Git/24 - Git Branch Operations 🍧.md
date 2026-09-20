

## 1. Creating a New Branch

### Basic Branch Creation
```bash
# Create a new branch from your current position
git branch feature-payment

# Create branch from a specific commit or branch
git branch feature-payment main
git branch hotfix a1b2c3d  # From specific commit hash
```

### Create and Switch (Most Common)
```bash
# Create and immediately switch to the new branch - OLD WAY
git checkout -b feature-payment

# Create and switch from specific starting point - OLD WAY
git checkout -b feature-payment main
git checkout -b hotfix a1b2c3d

# Modern equivalent (recommended)
git switch -c feature-payment

# Create from specific starting point - MODERN WAY
git switch -c feature-payment main
git switch -c hotfix a1b2c3d
```

### `git checkout -b` vs `git switch -c`

**`git checkout -b` (Traditional)**
```bash
# Traditional way - still widely used
git checkout -b new-feature
git checkout -b new-feature main
git checkout -b new-feature commit-hash

# Pros: Works on all Git versions, familiar to most developers
# Cons: checkout has multiple purposes (files and branches), can be confusing
```

**`git switch -c` (Modern)**
```bash
# Modern way - more intuitive
git switch -c new-feature
git switch -c new-feature main
git switch -c new-feature commit-hash

# Pros: Clear purpose (only for branches), better error messages
# Cons: Requires Git 2.23+ (Oct 2019), less familiar to some developers
```

### When to Use Which

```bash
# For maximum compatibility (older systems, scripts)
git checkout -b feature-payment

# For clarity and better UX (personal use, new projects)
git switch -c feature-payment

# They are functionally equivalent - choose based on your needs
```

### Creating Branches from Different Points
```bash
# From current branch (default)
git checkout -b new-feature        # Traditional
git switch -c new-feature          # Modern

# From main branch
git checkout -b new-feature main   # Traditional  
git switch -c new-feature main     # Modern

# From a specific tag
git checkout -b new-version v1.2.3
git switch -c new-version v1.2.3

# From a remote branch
git checkout -b local-feature origin/remote-feature
git switch -c local-feature origin/remote-feature

# From a specific commit
git checkout -b experiment a1b2c3d
git switch -c experiment a1b2c3d
```

### Pushing New Branch to Remote
```bash
# After creating locally, push to remote
git push -u origin feature-payment
# The -u flag sets up tracking relationship
```

---

## 2. Switching Between Branches

### Basic Switching
```bash
# Switch to an existing branch - OLD WAY
git checkout main
git checkout feature-payment

# Switch to an existing branch - MODERN WAY
git switch main
git switch feature-payment
```

### Switching with Uncommitted Changes
```bash
# If you have uncommitted changes:

# Option 1: Stash changes first
git stash
git checkout other-branch        # Traditional
git switch other-branch          # Modern
git stash pop  # Later when you return

# Option 2: Commit changes first
git add .
git commit -m "WIP: current changes"
git checkout other-branch
git switch other-branch

# Option 3: Force switch (discards changes - DANGEROUS)
git checkout --force other-branch    # Traditional
git switch --discard-changes other-branch  # Modern
```

### Advanced Switching Scenarios
```bash
# Switch to previous branch (handy shortcut)
git checkout -   # Traditional
git switch -     # Modern

# Create new branch from remote and switch to it
git checkout -b local-feature origin/remote-feature  # Traditional
git switch -c local-feature origin/remote-feature    # Modern

# Switch to a branch that exists remotely but not locally
git checkout --track origin/remote-branch    # Traditional
git switch --track origin/remote-branch      # Modern
```

### Checking Current Status
```bash
# See which branch you're currently on
git status
git branch    # Asterisk * shows current branch
git log --oneline -5  # Recent commits on current branch
```

---

## 3. Merge Base

### What is Merge Base?
The **merge base** is the **most recent common ancestor** of two branches. It's the point where the branches diverged.

```
A---B---C---D  main
     \
      E---F---G  feature
      ^
      |
  Merge Base (commit B)
```

### Finding Merge Base
```bash
# Find the merge base between current branch and main
git merge-base HEAD main

# Find merge base between any two branches/commits
git merge-base feature-branch main
git merge-base a1b2c3d x4y5z6e

# Show the actual commit (more useful)
git merge-base --all feature main
git show $(git merge-base feature main)
```

### Practical Uses of Merge Base

**1. See what changed since branches diverged:**
```bash
# Show commits on current branch since it diverged from main
git log $(git merge-base HEAD main)..HEAD

# Show commits on feature that aren't in main
git log $(git merge-base feature main)..feature
```

**2. Check for potential conflicts:**
```bash
# See what would change if we merged
git diff $(git merge-base feature main)...feature
```

**3. Create a patch since divergence:**
```bash
# Create patch of changes since branches split
git format-patch $(git merge-base feature main)..feature --stdout > changes.patch
```

### Three-Dot vs Two-Dot Syntax
```bash
# Two-dot: Commits reachable from B but not A
git log main..feature    # What's in feature but not main

# Three-dot: Commits reachable from either but not both
git log main...feature   # All commits since divergence
```

---

## 4. Branch Tips (HEAD References)

### What are Branch Tips?
The **tip** of a branch is the **most recent commit** on that branch. `HEAD` is a special pointer that refers to your current branch tip.

### Understanding HEAD
```bash
# HEAD points to your current branch tip
cat .git/HEAD    # Shows what HEAD points to

# When on main branch:
HEAD -> refs/heads/main

# When on feature branch:
HEAD -> refs/heads/feature
```

### Detached HEAD State
```bash
# When HEAD points directly to a commit, not a branch
git checkout a1b2c3d   # You're now in "detached HEAD" state - Traditional
git switch --detach a1b2c3d  # Modern way to enter detached HEAD

# To get out of detached HEAD:
git checkout main        # Traditional
git switch main          # Modern
git switch -c new-branch  # Create new branch from detached state
```

### Working with Branch Tips
```bash
# See the tip commit of current branch
git show HEAD
git log -1

# See tip of another branch
git show feature-branch
git log -1 feature-branch

# Compare tips of two branches
git diff main..feature
git diff HEAD..origin/main
```

### Relative References with Tips
```bash
# Relative to current HEAD
HEAD~1    # First parent of HEAD
HEAD~2    # Grandparent of HEAD
HEAD^     # First parent (same as ~1)
HEAD^^    # Grandparent (same as ~2)

# Multiple parents (merge commits)
HEAD^1    # First parent
HEAD^2    # Second parent

# Examples:
git show HEAD~1        # Show parent commit
git diff HEAD~3..HEAD  # Changes in last 3 commits
git log HEAD~5..HEAD   # Last 5 commits
```

---

## Practical Workflow Examples

### Complete Feature Development Flow
```bash
# 1. Start from main
git checkout main       # Traditional
git switch main         # Modern
git pull origin main

# 2. Create new feature branch
git checkout -b feature-user-profile        # Traditional
git switch -c feature-user-profile          # Modern

# 3. Do work and commit
git add .
git commit -m "Add user profile page"

# 4. Check what's changed since we started
git log $(git merge-base HEAD main)..HEAD

# 5. Push to remote
git push -u origin feature-user-profile

# 6. Create Pull Request targeting main
```

### Checking Branch Relationships
```bash
# See how branches relate to each other
git log --oneline --graph --all -10

# Check if current branch is ahead/behind main
git status

# More detailed view
git log --oneline main..HEAD   # Our unique commits
git log --oneline HEAD..main   # Main's unique commits
```

### Resync Feature Branch with Main
```bash
# On feature branch
git checkout feature-user-profile    # Traditional
git switch feature-user-profile      # Modern

# Check merge base
git merge-base HEAD main

# Update with latest main changes
git fetch origin
git merge origin/main
# OR
git rebase origin/main
```

### Quick Reference Commands

| Task | Traditional Command | Modern Command |
|------|-------------------|----------------|
| Create & switch | `git checkout -b new-branch` | `git switch -c new-branch` |
| Switch branch | `git checkout branch-name` | `git switch branch-name` |
| Switch to previous | `git checkout -` | `git switch -` |
| Find merge base | `git merge-base branch1 branch2` | `git merge-base branch1 branch2` |
| See branch tip | `git show branch-name` | `git show branch-name` |
| Compare branches | `git diff main..feature` | `git diff main..feature` |
| Recent changes | `git log $(git merge-base feat main)..feat` | `git log $(git merge-base feat main)..feat` |
| Branch status | `git status` or `git branch -v` | `git status` or `git branch -v` |

## Key Takeaways

- **`git checkout -b`**: Traditional, works everywhere, but multi-purpose
- **`git switch -c`**: Modern, clearer intent, requires Git 2.23+
- **Both create and switch to a new branch** - functionally equivalent
- **Choose based on**: Your Git version, team preferences, and need for clarity

These concepts form the foundation of effective Git workflow management, helping you navigate, understand, and manipulate your repository's history with precision.

### Tags : [[0 - Git 🍋‍🟩]]