# Git Branches & Remotes: Complete Guide

## Part 1: What Are Branches?

A **branch** is just a movable pointer to a commit. That's it. When you commit, the branch pointer moves forward automatically.

```
main:    A --- B --- C
                      ↑
                    main

feature: A --- B --- C --- D --- E
                                ↑
                             feature
```

- `main` (or `master`) = default branch, stable code
- `feature` = your isolated work
- Branches are **cheap** (40 bytes), so use them liberally

---

## Part 2: Essential Branch Commands

### Create & Switch
```bash
git branch                    # list local branches
git branch -a                 # list ALL (including remote-tracking)
git branch -v                 # list with last commit
git branch feature-login      # create branch (stay on current)
git switch feature-login      # switch to it (modern)
git checkout feature-login    # switch to it (old syntax)
git switch -c feature-login   # create + switch in one step
git checkout -b feature-login # same, old syntax
```

### Rename & Delete
```bash
git branch -m old-name new-name    # rename
git branch -m new-name             # rename current branch
git branch -d feature-login        # delete (safe — refuses if unmerged)
git branch -D feature-login        # delete (force — loses work!)
git push origin --delete feature-login  # delete branch on remote
```

### Merge & Rebase
```bash
git switch main
git merge feature-login            # merge feature into main
git merge --no-ff feature-login    # force merge commit (preserves history)
git rebase main                    # replay current branch on top of main
git rebase -i HEAD~3               # interactive rebase last 3 commits
```

### Stash (park changes temporarily)
```bash
git stash                          # save uncommitted changes
git stash list                     # see stashes
git stash pop                      # restore + delete stash
git stash apply                    # restore, keep stash
git stash drop                     # delete a stash
```

---

## Part 3: Remotes (GitHub)

A **remote** is a named URL to another copy of the repo. `origin` = default name for the one you cloned from.

### Remote Commands
```bash
git remote -v                      # list remotes with URLs
git remote add origin <url>        # add remote
git remote remove origin           # remove remote
git remote set-url origin <url>    # change URL
git remote show origin             # detailed info
```

### Fetch vs Pull vs Push
```bash
git fetch origin                   # download changes, DON'T touch your branch
git fetch --all --prune            # fetch all remotes, remove dead branches
git pull origin main               # fetch + merge into current branch
git pull --rebase origin main      # fetch + rebase (cleaner history)
git push origin main               # upload your commits
git push -u origin feature-login   # push + set upstream (only first time)
git push                           # after -u, this is enough
git push --force-with-lease        # safer force push (see rules below)
git push --force                   # DANGEROUS — overwrites remote
```

### Remote-Tracking Branches
When you clone or fetch, Git creates `origin/main`, `origin/feature` etc. These are **read-only mirrors** of what's on the remote.

```
Your local main  →  tracks  →  origin/main  →  reflects  →  GitHub main
```

Set upstream:
```bash
git branch --set-upstream-to=origin/main main
git push -u origin main    # shorthand
```

---

## Part 4: The Golden Rules (Don't Fuck Up)

### 🧍 Working ALONE

1. **Commit small, commit often.** Each commit = one logical change.
2. **Write real commit messages:**
   ```
   feat: add login form validation
   
   - Validate email format
   - Require password >= 8 chars
   ```
3. **Branch for everything** — even small fixes. `main` should always work.
4. **Never `git push --force` to `main`.**
5. **`git status` before every command.** Know what state you're in.
6. **Use `git reflog`** — your safety net. Every commit you ever made is here for ~90 days:
   ```bash
   git reflog
   git reset --hard HEAD@{3}   # recover anything
   ```

### 👥 Working WITH A TEAM

1. **Never rewrite shared history.** No `rebase` or `--force` on `main`/`develop`.
2. **Pull before you start working** — every day, every session:
   ```bash
   git switch main
   git pull --rebase
   ```
3. **Work on your own branch. Push it. Open a PR.**
4. **Use `--force-with-lease` instead of `--force`** on YOUR feature branch:
   ```bash
   git push --force-with-lease
   ```
   It refuses to push if someone else pushed in the meantime.
5. **Never commit secrets, `.env`, passwords, API keys.**
6. **Rebase YOUR branch before PR, never the shared branch:**
   ```bash
   git switch my-feature
   git fetch origin
   git rebase origin/main
   # fix conflicts, then:
   git push --force-with-lease
   ```
7. **Squash trivial commits before merging** (or let GitHub do it).

---

## Part 5: The Team Workflow (Standard)

```bash
# 1. Sync main
git switch main
git pull --rebase

# 2. Create feature branch
git switch -c feat/user-profile

# 3. Work, commit frequently
git add .
git commit -m "feat: add profile page skeleton"
# ... more commits ...

# 4. Push branch first time
git push -u origin feat/user-profile

# 5. Before opening PR, update against main
git fetch origin
git rebase origin/main
# resolve conflicts if any
git push --force-with-lease

# 6. Open PR on GitHub → review → merge (squash merge usually)

# 7. Clean up
git switch main
git pull --rebase
git branch -d feat/user-profile
git push origin --delete feat/user-profile
```

---

## Part 6: Handling Conflicts

When `git pull`, `merge`, or `rebase` hits conflicts:

```bash
# See which files conflict
git status

# Open the file — look for:
# <<<<<<< HEAD
# your version
# =======
# their version
# >>>>>>> origin/main

# Edit to the CORRECT final version, remove markers, save.

git add <file>            # mark resolved
git merge --continue      # or: git rebase --continue
# or abort:
git merge --abort
git rebase --abort
```

**Conflict pro-tip:** If it's a huge mess, abort, then ask the other person. Don't guess.

---

## Part 7: Undo Cheat Sheet

| Situation | Command |
|---|---|
| Unstage a file | `git restore --staged <file>` |
| Discard changes in file | `git restore <file>` |
| Amend last commit message | `git commit --amend` |
| Undo last commit, keep changes | `git reset --soft HEAD~1` |
| Undo last commit, discard changes | `git reset --hard HEAD~1` |
| Revert a pushed commit (safe) | `git revert <sha>` |
| Undo a pushed merge | `git revert -m 1 <merge-sha>` |
| Recover lost commit | `git reflog` → `git reset --hard HEAD@{n}` |
| See what changed | `git diff`, `git diff --staged`, `git log -p` |

**Rule:** If it's pushed and shared → use `git revert`. If it's local only → `git reset`.

---

## Part 8: Rules Summary (Print This)

**Always:**
- `git status` before acting
- Pull with `--rebase` on main
- Branch per feature/task
- Small commits with real messages
- `--force-with-lease` never `--force` on shared branches
- Test before pushing

**Never:**
- Force push to `main`/`develop`
- Commit secrets
- Rebase a branch others are working on
- `git add .` blindly (check with `git status` first)
- Panic — `git reflog` can recover almost anything

**Emergency:**
- Something broke? `git reflog` first, then `git status`
- Still lost? Don't run more commands. Copy the repo folder, then ask.

---

## Part 9: Mental Model Cheat Card

```
Local                          Remote (GitHub)
─────                          ───────────────
main          ⇄  origin/main  ⇄  main
feature-x     ⇄  origin/feature-x ⇄  feature-x

Commit  = save locally
Push    = send commits to remote
Fetch   = download remote state (safe)
Pull    = fetch + integrate (merge/rebase)
Pull Request = ask to merge your branch into main
```

**The one-sentence rule:** *Work on your own branch, sync from main often, push to your branch, PR into main, never rewrite shared history.*

That's it — you're now more competent than 90% of devs who just memorize `git push` and pray.


[[0 - Git 🍋‍🟩]]