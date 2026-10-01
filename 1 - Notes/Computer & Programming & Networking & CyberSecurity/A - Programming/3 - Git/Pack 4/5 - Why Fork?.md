

You fork **when you want to contribute to a project you don't own and don't have write access to.**

That's it — that's the entire reason forks exist. Without a fork, you'd hit a wall immediately:

```bash
git clone https://github.com/OriginalOwner/some-project.git
cd some-project
# make changes, commit...
git push
```

```
remote: Permission to OriginalOwner/some-project.git denied
```

You cloned it fine (clone never needs permission — it's just a download). But **pushing** requires write access, and almost nobody has write access to someone else's open-source repo by default.

**Forking solves this** by giving you your **own copy** of the repo, under your own account, where _you_ have full write access — so you can push freely there, then ask the original owner to pull your changes in via a Pull Request.

---

## The One-Sentence Version

> Fork = "give me my own writable copy of this repo, so I can make changes and then _propose_ them back to the original owner, without ever needing permission to touch their repo directly."

---

## The Fork Workflow, Step by Step

### 1. Fork on GitHub (web UI)

Click "Fork" on the original repo's page → GitHub creates `YourUsername/project`, a full copy, under your account.

### 2. Clone YOUR fork (not the original)

```bash
git clone https://github.com/YourUsername/project.git
cd project
```

### 3. Add the original as a second remote

```bash
git remote add upstream https://github.com/OriginalOwner/project.git
```

Now you have two remotes:

```bash
git remote -v
```

```
origin    https://github.com/YourUsername/project.git     (your fork — you can push here)
upstream  https://github.com/OriginalOwner/project.git     (original — read-only for you)
```

### 4. Create a branch for your change

```bash
git switch -c fix-typo
```

### 5. Make your change, commit

```bash
git add README.md
git commit -m "fix: typo in installation steps"
```

### 6. Push to YOUR fork (origin)

```bash
git push -u origin fix-typo
```

### 7. Open a Pull Request

On GitHub, go to your fork → "Compare & pull request" → this proposes merging your `fix-typo` branch from **your fork** into the original repo's `main` branch. The project owner reviews it, and if approved, **they** merge it — you never needed write access to their repo at any point.

### 8. Keep your fork synced over time

```bash
git fetch upstream
git switch main
git merge upstream/main      # bring the original's latest changes into your fork
git push origin main           # update your fork on GitHub too
```

---

## Visual Summary

```
OriginalOwner/project  (upstream — you can only READ)
        ↑
        │ Pull Request
        │
YourUsername/project  (origin — you can READ + WRITE)
        ↑
        │ git push
        │
Your local clone
```

---

**One-line answer to remember:**

> You fork because you lack write access to a repo — it gives you your own writable copy to work in, and a Pull Request is how you propose merging your fork's changes back into the original, without ever needing direct permission.


[[0 - Git]]