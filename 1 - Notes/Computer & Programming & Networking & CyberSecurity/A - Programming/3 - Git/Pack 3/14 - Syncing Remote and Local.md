

---

## 1. The Core Problem Syncing Solves

Your local repo and the remote repo are **independent copies** that only update each other when you explicitly tell them to (`fetch`, `pull`, `push`). Between those moments, they can drift apart — you commit locally, someone else pushes remotely, and now the two histories don't match. **Syncing** is the general term for the process of reconciling that drift, in either direction.

```
Local:   A---B---C          (your new local commits)
Remote:  A---B---D          (someone else's new commits)
```

---

## 2. The Three Sync Directions

|Direction|Goal|Commands|
|---|---|---|
|**Remote → Local**|Bring remote's new commits into your local branch|`fetch` + `merge`/`rebase`, or `pull`|
|**Local → Remote**|Send your new commits up to the remote|`push`|
|**Both (diverged)**|Reconcile differences both ways|`pull` (integrate) then `push`|

---

## 3. Checking Sync Status (Always Do This First)

```bash
git fetch                # update your knowledge of remote, without changing anything else
git status                # tells you: up to date / ahead / behind / diverged
```

`git status` after a fetch will say one of:

|Message|Meaning|
|---|---|
|`Your branch is up to date with 'origin/main'.`|Fully synced|
|`Your branch is ahead of 'origin/main' by N commits.`|You have local work to push|
|`Your branch is behind 'origin/main' by N commits.`|Remote has work you need to pull|
|`Your branch and 'origin/main' have diverged, ... N and M different commits`|Both sides changed — needs integration before pushing|

This is your **primary diagnostic tool** — always check it before deciding what to do next.

---

## 4. Case 1 — You're Behind (Remote Has New Commits)

```
Local:   A---B
Remote:  A---B---C---D
```

```bash
git pull
```

Fast-forwards your local branch straight to D — no merge commit needed, since there's no divergence.

---

## 5. Case 2 — You're Ahead (Local Has New Commits)

```
Local:   A---B---C---D
Remote:  A---B
```

```bash
git push
```

Simple fast-forward push — remote catches up to your history.

---

## 6. Case 3 — Diverged (Both Sides Have New Commits)

```
Local:   A---B---C
Remote:  A---B---D
```

This is exactly what happened with `webflyx` earlier. You have two sub-choices:

### Option A — Merge (preserves both histories, adds a merge commit)

```bash
git pull                  # fetch + merge → creates commit M with parents C and D
git push
```

```
Local:   A---B---C---M
              \-D---/
```

### Option B — Rebase (linear, rewrites your local commits)

```bash
git pull --rebase         # replays C on top of D
git push
```

```
Local:   A---B---D---C'   (C' = your commit C, replayed, new hash)
```

### Option C — You intentionally rewrote history (amend/interactive rebase) and remote's version should be discarded

```bash
git push --force-with-lease
```

This is the case from your earlier `webflyx` situation — you didn't want to integrate D, you wanted your rewritten history to **replace** it.

**How to tell which one you need:** if the divergence happened because someone else pushed _different, legitimate work_ → Option A or B (integrate both). If the divergence happened because _you_ rewrote a commit only you had (amend/rebase) → Option C (force push your intentional rewrite).

---

## 7. Visual Decision Tree

```
git fetch, then git status:

  "up to date"        → nothing to do
  "ahead"              → git push
  "behind"              → git pull (safe fast-forward)
  "diverged"            → did YOU rewrite history (amend/rebase)?
                             yes → git push --force-with-lease
                             no  → git pull (merge or --rebase), then git push
```

---

## 8. Syncing Multiple Branches at Once

```bash
git fetch --all --prune          # update every remote-tracking branch, clean stale ones
git branch -vv                    # see ahead/behind status for every local branch at a glance
```

There's no single command to "pull all branches" (pull only works on your current branch), but you can loop it:

```bash
for branch in $(git branch --format='%(refname:short)'); do
  git switch "$branch"
  git pull
done
git switch main   # return to main when done
```

---

## 9. Syncing a Fork with the Original Project

Covered earlier, but this is the classic multi-remote sync scenario:

```bash
git fetch upstream
git switch main
git merge upstream/main          # or: git rebase upstream/main
git push origin main               # push the sync to your own fork
```

---

## 10. Keeping a Feature Branch in Sync with `main` While You Work

Common daily pattern — your feature branch should periodically absorb new `main` commits so it doesn't drift too far and cause a painful merge later:

```bash
git switch feature-login
git fetch origin
git rebase origin/main            # replay your feature commits on top of latest main
# resolve any conflicts, git add, git rebase --continue
git push --force-with-lease        # required after rebase, since commits were rewritten
```

_(Only force-push feature branches that are yours alone / not being actively pulled by teammates.)_

---

## 11. Auto-Sync Safety Settings (Recommended Config)

```bash
git config --global fetch.prune true         # auto-remove stale remote-tracking branches on fetch
git config --global pull.rebase true          # rebase on pull (clean history) — or false for merge
git config --global rebase.autoStash true      # auto-stash/unstash uncommitted work during rebase
git config --global push.autoSetupRemote true  # auto-set tracking on first push of a new branch
```

---

## 12. Full Command Reference — Sync Toolkit

|Command|Purpose|
|---|---|
|`git fetch`|Update knowledge of remote (safe, no changes)|
|`git status`|Diagnose: up to date / ahead / behind / diverged|
|`git log main..origin/main --oneline`|See exactly what commits you're missing|
|`git log origin/main..main --oneline`|See exactly what commits you have that remote doesn't|
|`git pull`|Fetch + integrate (merge or rebase per config)|
|`git pull --rebase`|Fetch + rebase explicitly|
|`git push`|Send local commits to remote|
|`git push --force-with-lease`|Overwrite remote with intentionally rewritten local history|
|`git fetch --all --prune`|Sync tracking info for all remotes, clean stale refs|
|`git branch -vv`|See sync status of every local branch at once|

---

**One-line summary to remember:**

> Syncing is just answering one question repeatedly: _"who has commits the other doesn't?"_ — `fetch` + `status` tells you the answer, and from there it's always one of four moves: `push` (you're ahead), `pull` (you're behind), `pull` then `push` (diverged, integrate both), or `push --force-with-lease` (diverged, but you deliberately rewrote history and want yours to win).




[[0 - Git 🍋‍🟩]]