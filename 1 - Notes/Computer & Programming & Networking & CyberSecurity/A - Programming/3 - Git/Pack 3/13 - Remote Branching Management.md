

## 1. What a "Remote Branch" Actually Means (Recap + Precision)

There's no such thing as directly editing a branch that "lives on GitHub" from your machine. What you actually work with locally is a **remote-tracking branch** — a local, read-only snapshot of what a branch looked like on the remote **as of your last fetch/pull**.

```
.git/refs/remotes/<remote>/<branch>     ← e.g. origin/main
```

|Term|What it is|
|---|---|
|**Remote branch**|The actual branch, living on the server (GitHub)|
|**Remote-tracking branch**|Your local copy/reflection of that branch's last known state — `origin/main`|
|**Local branch**|Your own working branch — `main`|

You never modify `origin/main` directly. It only updates when you `fetch`, `pull`, or `push`.

---

## 2. Viewing Remote Branches

|Command|What it does|
|---|---|
|`git branch -r`|List remote-tracking branches only|
|`git branch -a`|List local **and** remote-tracking branches together|
|`git branch -vv`|Local branches with their tracked remote branch + ahead/behind count|
|`git ls-remote origin`|Query the **actual live remote** directly (bypasses your local cache entirely)|
|`git ls-remote --heads origin`|Same, but branches only (no tags)|
|`git remote show origin`|Detailed report: tracked branches, ahead/behind, stale branches|

`git ls-remote` is worth knowing specifically because it talks to the server **live** — useful when you suspect your local view is out of date and don't want to fully fetch yet.

---

## 3. Fetching Remote Branches

```bash
git fetch origin                    # update ALL remote-tracking branches for this remote
git fetch origin <branch>           # update just one remote-tracking branch
git fetch --all                     # fetch from every configured remote
git fetch --prune                   # fetch + remove stale remote-tracking branches no longer on server
```

After fetching, a remote branch that didn't exist locally as a tracking ref before will now appear under `git branch -r` — but you still don't have a _local_ branch for it yet (next section).

---

## 4. Checking Out a Remote Branch Locally

If someone else pushed `feature-x` to GitHub and you want to work on it:

```bash
git fetch origin
git switch feature-x
```

Modern Git is smart here — if `feature-x` doesn't exist locally but matches exactly one remote-tracking branch (`origin/feature-x`), `git switch` (and `checkout`) **automatically creates a local branch that tracks it.** This is equivalent to the older explicit form:

```bash
git switch -c feature-x origin/feature-x
# or older syntax:
git checkout -b feature-x origin/feature-x
git checkout --track origin/feature-x
```

---

## 5. Pushing Branches to Remote

|Command|What it does|
|---|---|
|`git push origin <branch>`|Push a branch, creating it on remote if it doesn't exist|
|`git push -u origin <branch>`|Push **and** set upstream tracking (do once per new branch)|
|`git push`|Push current branch to its already-set upstream|
|`git push origin HEAD`|Push current branch, whatever it's named, without typing the name|
|`git push origin HEAD:<branch>`|Push current branch to a **differently named** branch on remote|
|`git push --all origin`|Push all local branches to remote|

---

## 6. Deleting Remote Branches

|Command|What it does|
|---|---|
|`git push origin --delete <branch>`|Delete a branch on the remote|
|`git push origin :<branch>`|Older/alternate syntax for the same thing|

**Important:** this does **not** delete your local branch or local remote-tracking ref automatically in older Git — clean those up too:

```bash
git branch -d <branch>                 # delete local branch
git fetch --prune                       # remove the now-stale origin/<branch> tracking ref
```

---

## 7. Setting / Changing / Removing Tracking

|Command|What it does|
|---|---|
|`git branch -u origin/<branch>`|Set (or change) which remote branch your current local branch tracks|
|`git branch --set-upstream-to=origin/<branch> <local-branch>`|Same, explicit form, works on any branch (not just current)|
|`git branch --unset-upstream`|Remove tracking from current branch|
|`git branch -vv`|Confirm what's tracking what|

---

## 8. Syncing a Local Branch with Its Remote

```bash
git fetch origin
git merge origin/<branch>        # merge remote changes in
# or
git rebase origin/<branch>       # rebase local commits on top of remote's
# or, shorthand for either (per your pull.rebase config):
git pull
```

---

## 9. Pruning Stale Remote-Tracking Branches

Over time, branches get deleted on GitHub (e.g. after PR merges), but your local `origin/<branch>` refs don't disappear automatically unless you clean them:

```bash
git remote prune origin          # remove stale remote-tracking refs for one remote
git fetch --prune                 # fetch + prune in one step
git config --global fetch.prune true   # make pruning automatic on every fetch
```

Recommended to set globally — keeps `git branch -a` from accumulating dead branches forever.

---

## 10. Comparing Local vs Remote Branch State

|Command|What it does|
|---|---|
|`git log main..origin/main --oneline`|Commits remote has that you don't (you're behind)|
|`git log origin/main..main --oneline`|Commits you have that remote doesn't (you're ahead)|
|`git diff main origin/main`|Full content diff between local and remote branch|
|`git status`|Quick ahead/behind/diverged summary (after a fetch)|

---

## 11. Renaming a Branch (Local + Remote, Properly)

Renaming isn't a single remote operation — it's really: delete old, push new.

```bash
git branch -m old-name new-name              # rename locally
git push origin --delete old-name             # remove old name from remote
git push -u origin new-name                    # push new name, set tracking
```

---

## 12. Full Table — Every Remote Branch Command

|Command|Purpose|
|---|---|
|`git branch -r`|List remote-tracking branches|
|`git branch -a`|List local + remote-tracking branches|
|`git branch -vv`|Show tracking + ahead/behind|
|`git ls-remote origin`|Query the live remote directly|
|`git remote show origin`|Detailed remote branch report|
|`git fetch origin`|Update all remote-tracking branches|
|`git fetch --prune`|Update + remove stale tracking refs|
|`git switch -c <name> origin/<name>`|Check out a remote branch locally|
|`git push -u origin <name>`|Push + set tracking|
|`git push origin --delete <name>`|Delete a branch on remote|
|`git branch -u origin/<name>`|Set/change tracking|
|`git branch --unset-upstream`|Remove tracking|
|`git remote prune origin`|Clean stale tracking refs|
|`git config --global fetch.prune true`|Auto-prune on every fetch|

---

**One-line summary to remember:**

> You never touch a remote branch directly — you interact with a local **remote-tracking branch** (`origin/<name>`) that's synced via `fetch`/`push`, and you manage the relationship between your local branches and those tracking refs explicitly (`-u`, `--set-upstream-to`, `--unset-upstream`) so `pull`/`push` know where to go without arguments.




[[0 - Git 🍋‍🟩]]