
## `git log` with **Remote Branches**

You **cannot** run `git log remote` directly — it's invalid syntax.  
But you **can** view the commit history of **any remote-tracking branch** (e.g., `origin/main`, `upstream/dev`) using `git log`.

---

### Correct Syntax

```bash
git log <remote>/<branch>
```

---

## Common Examples

### 1. View log of `origin/main`
```bash
git log origin/main
```

### 2. View log of `upstream/main`
```bash
git log upstream/main
```

### 3. One-line summary
```bash
git log --oneline origin/main
```

### 4. Show only commits **not in your local branch**
```bash
git log HEAD..origin/main --oneline
```
> Shows what’s on remote but **not in your current branch**.

### 5. Show commits **you have but remote doesn’t**
```bash
git log origin/main..HEAD --oneline
```
> Useful before pushing.

---

## First: Make Sure Remote Data is Up-to-Date

```bash
git fetch origin    # or upstream, or --all
```

Then run any `git log` command above.

---

## List All Remote Branches

```bash
git branch -r
```
Example output:
```
  origin/main
  origin/dev
  upstream/main
  upstream/feature-x
```

Now you can log any of them:
```bash
git log origin/dev --oneline
```

---

## Compare Local vs Remote

```bash
# See difference in commits
git log --oneline --graph --decorate HEAD origin/main
```

Or visually:
```bash
git log --oneline --graph --all
```

---

## Pro Tips

| Goal | Command |
|------|---------|
| See latest commit on `origin/main` | `git log -1 origin/main` |
| Show patch (diff) of new commits | `git log -p HEAD..origin/main` |
| Graph view of local + remote | `git log --graph --oneline --decorate --all` |

---

## Example Workflow (Sync Fork)

```bash
# 1. Fetch latest from original repo
git fetch upstream

# 2. See what’s new in upstream/main
git log --oneline HEAD..upstream/main

# 3. Merge it
git checkout main
git merge upstream/main

# 4. Push to your fork
git push origin main
```

---

## Invalid Commands (Don’t Use)

```bash
git log remote          # Invalid
git log origin          # Invalid (origin is remote, not branch)
```

**Correct**: `git log origin/main`, `git log upstream/feature`

---

## Quick Cheat Sheet

```bash
# Update remotes
git fetch --all

# View remote branch log
git log --oneline origin/main
git log --oneline upstream/main

# See what you'll get from remote
git log HEAD..origin/main --oneline

# See what you'll push
git log origin/main..HEAD --oneline
```

---


##### Tags : [[0 - Git 🍋‍🟩]]