it! Keep taking notes—here's a **quick reference card** for the Git commands we've covered:

## Git Remote Workflow Summary

| Step | Command | Purpose |
|------|---------|---------|
| **List remotes** | `git remote -v` | See `origin` & `upstream` URLs |
| **Add upstream** | `git remote add upstream <original-url>` | Link to original repo |
| **Fetch updates** | `git fetch upstream` | Download changes (no merge) |
| **View remote log** | `git log --oneline HEAD..upstream/main` | See **new commits** only |
| **Sync fork** | `git fetch upstream && git merge upstream/main && git push` | Full update + push |

---

## One-Command Sync (Copy-Paste Ready)
```bash
git fetch upstream && git checkout main && git merge upstream/main && git push origin main
```

---
**Git: Branches vs. Upstreams – Key Differences**

| Aspect | **Branch** | **Upstream** |
|--------|------------|--------------|
| **What it is** | A **local** (or remote) pointer to a commit. It lets you work on separate lines of development. | A **tracking relationship** that links a **local branch** to a **remote branch** (e.g., `origin/main`). |
| **Created by** | `git branch <name>` or `git checkout -b <name>` (creates locally).<br>`git push -u origin <name>` also creates a remote branch. | `git branch --set-upstream-to=<remote>/<branch> <local-branch>`<br>or automatically with `git push -u` / `git pull` on a new branch. |
| **Stored where** | In `.git/refs/heads/` (local) or on the remote repository under `refs/heads/`. | In the local repo’s config file (`.git/config`) under the branch’s section: <br>`[branch "main"]`<br>`    remote = origin`<br>`    merge = refs/heads/main` |
| **Purpose** | Isolate work, feature development, bug fixes, experiments. | Simplify `git pull`, `git push`, `git status` by knowing **where to fetch from / push to** without typing the remote name every time. |
| **Visibility** | `git branch -a` shows all local + remote-tracking branches. | `git branch -vv` shows each local branch with its upstream (e.g., `main  a1b2c3d [origin/main] …`). |
| **Commands that use it** | `git checkout <branch>`, `git merge <branch>`, `git rebase <branch>`. | `git pull` (pulls from upstream), `git push` (pushes to upstream), `git status` (shows ahead/behind counts). |
| **Can exist without the other?** | Yes – you can have a local branch with **no upstream**. | No – an upstream always refers to a **remote branch** that a local branch tracks. |

---

### Quick Example

```bash
# 1. Create a local branch
git checkout -b feature/login

# 2. Push it and set upstream in one step
git push -u origin feature/login
```

Now:
- **`feature/login`** = local branch.
- **`origin/feature/login`** = remote branch.
- **Upstream** of `feature/login` = `origin/feature/login`.

```bash
git branch -vv
# * feature/login  4f5g6h7 [origin/feature/login] Add login UI
```

```bash
git pull          # pulls from origin/feature/login
git push          # pushes to origin/feature/login
```

---

### Common Operations

| Task | Branch command | Upstream command |
|------|----------------|------------------|
| List all branches | `git branch -a` | — |
| See upstream for current branch | — | `git rev-parse --abbrev-ref --symbolic-full-name @{u}` |
| Change upstream | — | `git branch --set-upstream-to=origin/new-name` |
| Remove upstream | — | `git branch --unset-upstream` |

---

### TL;DR

- **Branch** = a movable pointer to a commit (your line of work).  
- **Upstream** = a *link* that tells Git **which remote branch** your local branch should sync with.  

Use branches to organize code; set an upstream to make `push`/`pull` painless.
##### Tags : [[0 - Git 🍋‍🟩]]