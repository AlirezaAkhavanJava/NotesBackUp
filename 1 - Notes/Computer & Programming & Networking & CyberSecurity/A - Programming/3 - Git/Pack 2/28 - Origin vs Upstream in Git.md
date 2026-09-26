


Both are just **remote names** (aliases for repository URLs), but by convention they refer to different things in a **fork-based workflow**.

## Definitions

| Name | Typically points to | Who owns it |
|------|--------------------|-------------|
| **origin** | *Your* fork of the repository | You |
| **upstream** | The *original* repository you forked from | The project maintainers |

> ⚠️ These are **conventions, not special keywords**. Git treats them identically — they're just names pointing to URLs. You could call them `banana` and `apple` and Git wouldn't care.

## Visual: The Fork Workflow

```
   Original repo (maintainers)
   github.com/facebook/react          ← "upstream"
            │
            │  fork
            ▼
   Your copy (you)
   github.com/yourname/react          ← "origin"
            │
            │  clone
            ▼
   Your local machine
   ~/react
```

## Typical Setup

When you clone your fork, `origin` is set automatically. You add `upstream` manually:

```bash
# Clone your fork (origin is set automatically)
git clone git@github.com:yourname/react.git
cd react

# Add the original repo as upstream
git remote add upstream https://github.com/facebook/react.git

# Verify
git remote -v
# origin    git@github.com:yourname/react.git (fetch)
# origin    git@github.com:yourname/react.git (push)
# upstream  https://github.com/facebook/react.git (fetch)
# upstream  https://github.com/facebook/react.git (push)
```

## Common Workflows

**Push your work to your fork:**
```bash
git push origin main
```

**Keep your fork in sync with the original:**
```bash
git fetch upstream
git checkout main
git merge upstream/main      # or: git rebase upstream/main
git push origin main         # update your fork
```

**Pull in new changes from maintainers:**
```bash
git pull upstream main
```

## When There's No Fork

- **Direct contributor** (you have write access): there's usually just `origin` — no `upstream` needed.
- **Cloned someone else's repo** to use/read it: only `origin` exists.
- **Multiple remotes**: you can have many (`origin`, `upstream`, `fork2`, `colleague`, etc.).

## Quick Rules of Thumb

| Situation                    | Meaning                                          |
| ---------------------------- | ------------------------------------------------ |
| `origin` = your fork         | `git push origin <branch>` to save work          |
| `upstream` = source of truth | `git fetch upstream` to get latest official code |
| No fork involved             | `origin` is just "wherever you cloned from"      |

## Managing Remotes

```bash
git remote -v                    # list all remotes
git remote add upstream <url>    # add a remote
git remote rename origin old     # rename a remote
git remote remove upstream       # delete a remote
git remote set-url origin <url>  # change a remote's URL
```

## Summary

- **origin** = *your* copy (usually your fork) — where you push your work
- **upstream** = the *original* project — where you pull the latest official changes from
- Both are **arbitrary names**; the distinction is purely by convention in fork-based collaboration.


[[0 - Git 🍋‍🟩]]