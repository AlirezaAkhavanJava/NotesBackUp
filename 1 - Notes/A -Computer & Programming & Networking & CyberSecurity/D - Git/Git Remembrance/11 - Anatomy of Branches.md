


In standard industry workflows (like Git Flow or GitHub Flow), branches are categorized by their lifespan and purpose:

  

|**Branch Category**|**Naming Pattern**|**Purpose**|**Lifetime**|
|---|---|---|---|
|**Production / Main**|`main` or `master`|Contains stable, production-ready code. Anything here can be deployed immediately.|Permanent|
|**Development**|`develop`|The integration branch where upcoming feature branches are merged for testing before release.|Permanent|
|**Feature**|`feature/login-page`|Isolated work for a single feature or task. Branches off `develop` (or `main`).|Short-lived|
|**Bugfix**|`bugfix/nav-bar-overlap`|Addresses routine non-critical bugs found during development.|Short-lived|
|**Hotfix**|`hotfix/security-patch`|Critical patches applied directly to `main` to fix production outages, then back-merged to `develop`.|Short-lived|
|**Release**|`release/v2.1.0`|Pre-production stage for final testing, bug fixing, and version bumping before merging into `main`.|Temporary|

## When to Create a Branch

Create a new branch anytime you are about to write code that isn't a 10-second typo fix. A fresh branch should be created when:

  

- **Starting a new task/feature:** Keeps your experimental or unfinished code separate from stable code.
    
      
    
- **Investigating or testing an idea (Spike):** If you want to try a new library without breaking your working copy (`spike/try-zustand`).
    
      
    
- **Fixing a bug:** Ensures your fix can be code-reviewed and tested in isolation before deployment.
    
      
    
- **Context switching:** If you're halfway through Feature A and high-priority Bug B pops up, you can stash your work, switch branches, build a bugfix branch, and return to Feature A without losing anything.
    
      
    

## Dumb Mistakes People Make

1. **Committing Directly to `main`:** Working on `main` bypasses pull request reviews, risks pushing broken code into production, and makes local history hard to reconcile with teammates.
    
      
    
2. **Creating Mega-Branches:** Keeping a branch open for weeks or months while writing thousands of lines of code. This guarantees massive, nightmarish merge conflicts later.
    
      
    
3. **Pushing Secrets or Junk Files:** Forgetting to add `.env`, `node_modules/`, or build binaries to `.gitignore` before committing. Once committed, secrets remain in Git history even if you delete the file later.
    
      
    
4. **`git push --force` on Shared Branches:** Overwriting remote history on `main` or shared branches destroys your teammates' work and unsynchronizes their repositories.
    
      
    
5. **Branching Off the Wrong Base:** Running `git switch -c feature/b` while still sitting on `feature/a` instead of `main` or `develop`. Feature B now accidentally contains all unmerged changes from Feature A.
    
      
    
6. **Working in "Detached HEAD" State:** Checking out a commit hash directly (`git checkout a1b2c3d`) instead of a branch name, then making commits. Those commits are unattached to any branch and can easily be lost during garbage collection.
    
      
    

## Mechanics: Merge vs. Rebase

Both commands integrate changes from one branch into another, but they modify history differently.

  

### Git Merge

Combines two branch histories by creating a **merge commit**.

  

- **How it works:** Git looks at the common ancestor of both branches, compares the tip of each branch, and creates a new commit that has _two parent commits_.
    
      
    
- **Pros:** Preserves full, non-destructive historical truth.
    
      
    
- **Cons:** Can make your `git log` graph look like a messy web of intersecting lines ("diamond history").
    
      
    

### Git Rebase

Rewrites history by moving your commits onto the tip of another branch.

  

- **How it works:** Git takes all new commits on your branch, temporarily sets them aside, moves your branch base to the latest commit of `main`, and then replays your commits one by one on top.
    
      
    
- **Pros:** Produces a completely linear history without merge clutter.
    
      
    
- **Cons:** Rewrites commit SHA-1 hashes. **Never rebase a branch that has been pushed and shared with other developers.**
    
      
    

## Emergency Playbook: How to Fix Common Screw-Ups

### 1. "I accidentally made commits on `main` instead of a new branch"

If you haven't pushed yet, you can move your changes to a new branch and reset `main`:

  

Bash

```
# 1. Create the new branch where your commits currently sit
git branch feature/my-work

# 2. Roll back main by 1 commit (or N commits), leaving your files untouched locally
git reset --hard HEAD~1

# 3. Switch to your new branch where your work is safely preserved
git switch feature/my-work
```

### 2. "I completely broke my repo / deleted a branch and panicked"

Git almost never deletes object data immediately. Use **`git reflog`** (the log of where `HEAD` has pointed):

  

Bash

```
# 1. View history of every action you've taken in this local repo
git reflog

# Output looks like:
# e4f5a6b HEAD@{0}: checkout: moving from feature to main
# a1b2c3d HEAD@{1}: commit: Added broken code

# 2. Reset back to the exact commit state before the mistake
git reset --hard HEAD@{1}
```

### 3. "A Merge or Rebase went wrong and there are conflicts everywhere"

Abort the process and return your repository to the exact state it was in before you started:

  

Bash

```
# For a failed merge
git merge --abort

# For a failed rebase
git rebase --abort
```

### 4. "I pushed bad code or secrets to a shared remote branch"

Never use `--force` on a shared branch. Create a new commit that undoes the bad commit cleanly:

Bash

```
# Creates a new commit that flips the changes of the target commit
git revert <bad-commit-hash>

# Push the fix safely
git push origin main
```


[[0 - Git 🍋‍🟩]]