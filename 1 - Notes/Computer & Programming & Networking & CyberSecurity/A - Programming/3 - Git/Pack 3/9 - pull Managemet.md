

Everything you need to fully control how `git pull` behaves — strategies, config, conflict handling, and troubleshooting.

---

## 1. The Three Pull Strategies

|Strategy|Command|History Result|
|---|---|---|
|**Merge** (default)|`git pull`|Creates a merge commit if diverged|
|**Rebase**|`git pull --rebase`|Replays your commits on top — linear history|
|**Fast-forward only**|`git pull --ff-only`|Only succeeds if no divergence — refuses otherwise|

```bash
git pull                 # merge strategy (default)
git pull --rebase        # rebase strategy
git pull --ff-only        # safest — refuses if it would need a merge/rebase
```

---

## 2. Setting a Permanent Default Strategy

Instead of typing flags every time, set your preferred strategy globally:

```bash
git config --global pull.rebase false   # always merge (Git's factory default)
git config --global pull.rebase true    # always rebase
git config --global pull.ff only        # always require fast-forward, error otherwise
```

**Recommended for solo projects (like `webflyx`):**

```bash
git config --global pull.rebase true
```

Keeps history clean and linear — no clutter of merge commits for your own work.

**Recommended for team/shared branches:**

```bash
git config --global pull.rebase false
```

Merge preserves exact history of when branches diverged/rejoined — safer for shared collaboration.

---

## 3. Per-Branch Override

You can override the global default for a specific branch:

```bash
git config branch.main.rebase true
```

This makes `main` always rebase on pull, even if your global default is merge.

---

## 4. Setting Up Tracking (So Plain `git pull` Works)

```bash
git push -u origin main         # push + set tracking in one step
git branch -u origin/main       # set tracking without pushing
git branch --unset-upstream     # remove tracking
git branch -vv                  # see what each branch tracks + ahead/behind count
```

Without tracking set, `git pull` (no args) will error asking you to specify `<remote> <branch>` explicitly.

---

## 5. Reviewing Before You Pull (Best Practice)

```bash
git fetch origin
git log main..origin/main --oneline    # commits remote has that you don't
git log origin/main..main --oneline    # commits you have that remote doesn't
git diff main origin/main               # full diff of what would change
```

Then decide:

```bash
git merge origin/main      # or
git rebase origin/main
```

---

## 6. Handling Merge Conflicts During Pull

```bash
git pull
# CONFLICT (content): Merge conflict in App.java
```

```bash
git status                     # see which files are conflicted
# edit files, resolve <<<<<<< ======= >>>>>>> markers manually
git add <resolved-file>        # mark as resolved
git commit                     # completes the merge (message pre-filled)
```

To bail out entirely and go back to before the pull:

```bash
git merge --abort
```

---

## 7. Handling Conflicts During `pull --rebase`

Rebase conflicts work differently — resolve **one commit at a time**:

```bash
git pull --rebase
# CONFLICT in commit 1 of 3
```

```bash
# fix conflict markers in file
git add <resolved-file>
git rebase --continue      # move to next conflicting commit, repeat as needed
```

To escape:

```bash
git rebase --abort         # cancel entirely, return to pre-rebase state
git rebase --skip          # skip this specific commit (rare, use carefully)
```

---

## 8. Common Pull Problems & Fixes

|Problem|Cause|Fix|
|---|---|---|
|`fatal: no tracking information`|No upstream set for this branch|`git branch -u origin/main`|
|`Your branch and 'origin/main' have diverged`|Local history rewritten (amend/rebase) vs. remote|See below — often needs `--force-with-lease` push, not pull|
|Merge conflict during pull|Same lines changed both locally and remotely|Resolve manually, `git add`, `git commit`|
|`fatal: refusing to merge unrelated histories`|Pulling into a repo with a completely separate history (e.g. re-initialized repo)|`git pull origin main --allow-unrelated-histories`|
|Accidentally created unwanted merge commit|Used `pull` instead of `pull --rebase`|`git reset --hard origin/main` (if no valuable local commits) or rebase manually after|

---

## 9. Special Flags Reference

|Flag|What it does|
|---|---|
|`--ff-only`|Only allow fast-forward, error otherwise (no merge/rebase created)|
|`--no-ff`|Force a merge commit even if fast-forward is possible|
|`--rebase`|Use rebase instead of merge|
|`--rebase=interactive`|Rebase with interactive editing of commits|
|`--no-commit`|Fetch + merge, but pause before finalizing the merge commit (review first)|
|`--allow-unrelated-histories`|Allow merging two histories with no common ancestor|
|`--all`|Pull updates from all configured remotes|
|`--tags`|Also fetch/pull tags|
|`--prune`|Remove local remote-tracking branches deleted on the remote|
|`--dry-run`|Show what _would_ happen, without actually doing it|
|`-v` / `--verbose`|Detailed output|

---

## 10. Undoing a Bad Pull

```bash
git reflog                         # find the commit hash from before the pull
git reset --hard <hash-before-pull>   # roll back completely (careful — discards changes)
```

Or if it was a merge that just needs reverting (not discarding):

```bash
git revert -m 1 <merge-commit-hash>
```

---

## 11. Recommended Setup for You (Solo Debian Dev, `webflyx`)

```bash
git config --global pull.rebase true      # clean linear history on pull
git config --global rebase.autoStash true # auto-stash uncommitted changes before rebase, auto-pop after
```

`rebase.autoStash` is especially useful — it means you don't have to manually `git stash` before pulling if you have uncommitted work in progress.

---

**One-line summary to remember:**

> `git pull` = fetch + integrate — choose your integration strategy deliberately (`merge` for shared history, `rebase` for clean solo history, `--ff-only` for maximum safety), set it as a global default so you're not fighting flags every time, and always know how to `--abort` if a conflict goes sideways.

Want to go hands-on now and actually simulate a merge conflict in `webflyx` (edit the same line on two branches) so you practice resolving one safely before it happens for real?


[[0 - Git 🍋‍🟩]]