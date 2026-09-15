
At an architectural level, a Git branch is not a copy of your files, a directory, or a container—it is literally a **41-byte text file** inside `.git/refs/heads/<branch-name>` containing a 40-character commit hash pointing to a specific commit object in Git's object store.

---
![[Pasted image 20260915182844.png]]
### Under the Hood: The Mechanics of a Branch

Unlike older version control systems (like SVN) that duplicate the entire codebase directory when branching, Git branching costs virtually zero CPU time and disk space.

* **The Reference File:** If you open `.git/refs/heads/feature-login` in a text editor, you will see a single SHA-1 hash (e.g., `a1b2c3d4e5f6...`).
* **The HEAD Reference:** `.git/HEAD` is another reference file that points to your current branch reference (e.g., `ref: refs/heads/feature-login`).
* **How Commits Move the Pointer:** When you create a new commit, Git writes a new commit object (containing the parent commit hash, tree hash, author, and message). Git then automatically rewrites the hash inside `.git/refs/heads/<current-branch>` to point to the *new* commit object. The branch reference moves forward automatically; the parent commit history stays intact behind it.

---

### What is `origin`?

`origin` is simply the **default alias (nickname)** Git assigns to the remote repository URL from which you cloned (or connected) your local repository.

It is defined inside your local `.git/config` file:

```ini
[remote "origin"]
    url = git@github.com:username/repository.git
    fetch = +refs/heads/*:refs/remotes/origin/*

```

You can rename `origin` to anything (e.g., `upstream`, `github`, `server`), but `origin` is the global industry convention.

---

### The Three Layers of a Branch

When working with remotes, every branch exists across three distinct states:

| Branch Type | Reference Path | Role & Behavior |
| --- | --- | --- |
| **Local Branch** | `.git/refs/heads/main` | Your personal, editable workspace branch. You commit directly to this. |
| **Remote-Tracking Branch** | `.git/refs/remotes/origin/main` | A **read-only local cache** representing the last known state of `main` on the `origin` server. Updated when you run `git fetch` or `git pull`. |
| **Remote Branch** | Stored on GitHub/GitLab server | The actual branch living on the server that your teammates push to and pull from. |

---

### How to Work with Branches Properly

To maintain a clean commit history and avoid merge conflicts, follow these industry standards:

1. **Keep Branches Short-Lived:** A branch should represent a single task (a bugfix or feature). Merge or rebase it back into the main branch within days, not weeks.
2. **Use Consistent Naming Conventions:** Group branches logically using prefixes:
* `feature/user-authentication`
* `bugfix/header-alignment`
* `hotfix/auth-token-leak`


3. **Fetch and Rebase Frequently:** Before pushing or opening a Pull Request, integrate the latest changes from the main remote branch to keep history linear:
```bash
git fetch origin
git rebase origin/main

```


4. **Clean Up Stale Branches:** Delete local and remote branches immediately after they are merged to prevent reference clutter.

---

### Essential Branching Commands

```bash
# Create and switch to a new branch (modern syntax)
git switch -c feature/login-page

# Set up local branch to track the remote branch and push
git push -u origin feature/login-page

# View all branches (local and remote-tracking)
git branch -a

# Safely delete a local branch (only if merged)
git branch -d feature/login-page

# Delete a remote branch on origin
git push origin --delete feature/login-page

```


[[0 - Git 🍋‍🟩]]