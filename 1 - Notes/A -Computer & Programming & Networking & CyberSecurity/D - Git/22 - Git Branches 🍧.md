### The Core Concept: What is a Branch?

At its core, a **branch** is a lightweight, movable pointer to a specific commit in your repository's history. The default branch is typically called `main` or `master`.

Think of your commit history as a timeline. A branch is just a pointer that says, "This is the latest commit for this line of development."

---

## Part 1: Basic Branching (Everyday Usage)

### 1. Creating a Branch
You create a branch to isolate work (a new feature, a bug fix, etc.) without affecting the main codebase.

```bash
# Create a new branch named "feature-login"
git branch feature-login

# Create a new branch AND switch to it (common shortcut)
git checkout -b feature-login
# The modern equivalent of the above:
git switch -c feature-login
```

### 2. Switching Branches
To move your working directory to the state of a different branch.

```bash
# Switch to the 'main' branch
git checkout main

# Modern command (more intuitive)
git switch main

# Switch back to your feature branch
git switch feature-login
```

### 3. Viewing Branches
See a list of all branches in your repository. The current branch is marked with an asterisk (`*`).

```bash
git branch          # List local branches
git branch -a       # List ALL branches (local and remote)
git branch -v       # List branches with the latest commit info
```

### 4. Making Commits on a Branch
Once you're on a branch, any commits you make only exist on that branch. The `main` branch remains unchanged.

```bash
git add .
git commit -m "Implement user login functionality"
```

### 5. The `git status` Command
Your best friend. It tells you which branch you're on and the state of your working directory.

```bash
git status
# On branch feature-login
# Your branch is ahead of 'origin/main' by 1 commit.
```

### 6. Merging Branches
Once your feature is complete, you integrate it back into the `main` branch. This is typically done via a **Pull Request (PR)** or **Merge Request (MR)** on platforms like GitHub or GitLab, but the underlying command is `merge`.

**First, switch to the branch you want to merge INTO (usually `main`):**
```bash
git switch main
git pull origin main        # Get the latest changes from the remote
git merge feature-login     # Merge the feature branch into main
```

### 7. Deleting a Branch
After a branch has been merged, it's safe to delete it to keep your repository clean.

```bash
# Delete the branch locally
git branch -d feature-login

# If the branch hasn't been merged, Git will warn you.
# To force delete (use with caution!):
git branch -D feature-login
```

---

## Part 2: Intermediate Branching (Collaboration & Workflow)

### 8. Remote Branches
When you collaborate, you push your local branches to a remote server (like GitHub).

```bash
# Push your local branch to the remote for the first time
git push -u origin feature-login
# The `-u` flag sets the "upstream," linking your local branch to the remote one.

# Later, you can simply use:
git push

# To get the latest list of remote branches (e.g., after a teammate pushes one)
git fetch
```

### 9. Common Workflow: Feature Branching
This is the standard collaborative workflow:
1.  **Start from `main`:** `git checkout main && git pull`
2.  **Create a feature branch:** `git checkout -b feature/amazing-feature`
3.  **Do your work:** Make commits on your branch.
4.  **Push the branch:** `git push -u origin feature/amazing-feature`
5.  **Open a Pull Request:** On GitHub/GitLab, create a PR to merge `feature/amazing-feature` into `main`.
6.  **Review & Merge:** Teammates review your code. Once approved, it's merged via the platform.
7.  **Clean up:** Delete the remote branch on the platform and delete your local branch (`git branch -d feature/amazing-feature`).

### 10. Tracking & Updating Feature Branches
If `main` gets updated after you created your branch, you should bring those changes into your feature branch to avoid conflicts.

```bash
# While on your feature branch...
git switch my-feature

# Option 1: Merge main into your branch
git merge main

# Option 2: Rebase your branch onto main (for a cleaner history)
git rebase main
```
*(See "Advanced" section for more on rebasing)*

---

## Part 3: Advanced Branching (Power User Techniques)

### 11. Rebasing vs. Merging
Both integrate changes from one branch into another, but they do it differently.

*   **Merge:** Creates a new "merge commit" that ties the two histories together. Preserves the exact history but can look cluttered.
    
*   **Rebase:** "Replays" your commits on top of the target branch (e.g., `main`). Results in a linear, cleaner history.

    ```bash
    # Rebase the current branch onto main
    git switch my-feature
    git rebase main
    ```
    **Golden Rule of Rebasing:** Never rebase a public branch (one that others are using) that you have shared. Only rebase your local, private branches.

### 12. Interactive Rebase (`rebase -i`)
A powerful tool to clean up your commit history *before* sharing it. You can squash commits, reword messages, edit commits, or drop them.

```bash
# Rebase the last 4 commits
git rebase -i HEAD~4
```
This opens an editor allowing you to choose what to do with each commit.

### 13. Branch Force Pushing (`push --force-with-lease`)
After you rebase a branch, its history has changed. A normal `git push` will be rejected. You must **force push**. However, `--force-with-lease` is safer than `--force` as it will abort if someone else has pushed to the same branch in the meantime.

```bash
git push --force-with-lease origin my-feature
```

### 14. Detached HEAD
This is the state where `HEAD` (the pointer to your current working snapshot) is not pointing to a branch, but directly to a commit. It's useful for inspecting old code.

```bash
git checkout <commit-hash> # You are now in a "detached HEAD" state
```
To get out of it, simply check out a branch again: `git switch main`.

### 15. Cherry-Picking
Applies the changes from a specific commit (or range of commits) onto your current branch. Useful for porting a single bug fix from one branch to another without merging everything.

```bash
# Find the commit hash you want (e.g., a1b2c3d)
git log --oneline

# While on your target branch (e.g., main)
git cherry-pick a1b2c3d
```

### 16. Stashing for Quick Context Switching
Need to switch branches but you have uncommitted changes? Stash them!

```bash
git stash        # Save uncommitted changes away
git switch main  # Do your urgent work on main
git switch my-feature
git stash pop    # Re-apply your stashed changes
```

### Summary: From Basic to Advanced

| Level | Concept | Key Command(s) | Purpose |
| :--- | :--- | :--- | :--- |
| **Basic** | Create & Switch | `git switch -c <branch>`, `git checkout -b <branch>` | Start new work isolated from `main`. |
| | Viewing | `git branch` | See what branches exist. |
| | Merging | `git merge <branch>` | Integrate completed work back into `main`. |
| | Deleting | `git branch -d <branch>` | Clean up after merging. |
| **Intermediate** | Remote Branches | `git push -u origin <branch>`, `git fetch` | Share work and collaborate. |
| | Updating a Branch | `git merge main`, `git rebase main` | Keep your feature branch up-to-date. |
| **Advanced** | Rebasing | `git rebase main` | Create a linear project history. |
| | Interactive Rebase | `git rebase -i HEAD~n` | Clean up and edit local commit history. |
| | Force Pushing | `git push --force-with-lease` | Update a remote branch after history rewrite. |
| | Cherry-Picking | `git cherry-pick <commit>` | Apply a single specific commit. |
| | Stashing | `git stash`, `git stash pop` | Temporarily save and restore uncommitted changes. |

Mastering these concepts will make you highly proficient with Git and enable you to handle almost any version control scenario you encounter.

### Tags : [[0 - Git 🍋‍🟩]]