


`git push` uploads your local commits to a remote repository, updating the remote branch to match yours.

---

## What Happens Internally

```bash
git push origin main
```

1. Git checks: is your local `main` a **direct descendant** of the remote's `main`? (fast-forward check)
2. If yes → uploads any new objects (blobs/trees/commits) the remote doesn't have yet
3. Updates the remote's `main` ref to point to your latest commit
4. Updates your local `origin/main` remote-tracking branch to match

If your local branch is **behind** or **diverged** from the remote, push is **rejected** — this is exactly what happened with your `webflyx` amend earlier. Git refuses to silently overwrite commits that exist on the remote but not locally.

---

## Common Push Commands

|Command|What it does|
|---|---|
|`git push`|Push current branch to its tracked upstream|
|`git push origin main`|Push explicitly to `origin`'s `main` branch|
|`git push -u origin main`|Push **and** set upstream tracking (do once per new branch)|
|`git push --all`|Push all local branches|
|`git push --tags`|Push all tags|
|`git push origin <tag>`|Push a single specific tag|
|`git push origin --delete <branch>`|Delete a branch on the remote|
|`git push origin --delete <tag>`|Delete a tag on the remote|
|`git push --force`|Force overwrite remote history (dangerous — see below)|
|`git push --force-with-lease`|Safer force push — fails if remote has changes you haven't seen|
|`git push --force-if-includes`|Even safer — checks your remote-tracking ref is up to date before forcing|
|`git push --dry-run`|Show what _would_ be pushed, without pushing|
|`git push -v`|Verbose output|
|`git push --follow-tags`|Push commits **and** any annotated tags reachable from them, in one command|

---

## Fast-Forward Push (Normal Case)

```
Before:  origin/main → A → B
         local main   → A → B → C

After push: origin/main → A → B → C   (fast-forward, no conflict)
```

This is the default, safe, expected case — your branch is simply "ahead," so the remote just catches up.

---

## Non-Fast-Forward (Rejected Push)

```
Before:  origin/main → A → B
         local main   → A → C   (diverged — different commit than B)
```

Git rejects this outright, because pushing would **overwrite** commit B on the remote — data other people (or your other clones) might depend on.

**Two ways to resolve, same as with pull conflicts:**

```bash
git pull                    # merge/rebase remote changes in first, then push normally
# — or, if you intentionally rewrote history (amend/rebase) —
git push --force-with-lease  # tell Git you meant to replace remote's history
```

---

## `--force` vs `--force-with-lease` vs `--force-if-includes`

|Flag|Safety|Behavior|
|---|---|---|
|`--force`|Dangerous|Overwrites remote unconditionally, no checks|
|`--force-with-lease`|Safer|Refuses if remote has commits you haven't fetched yet|
|`--force-if-includes`|Safest|Also verifies your remote-tracking ref reflects the _actual_ latest fetch, not a stale one|

**Rule of thumb:** Never use plain `--force` on a shared branch. Always prefer `--force-with-lease` (or `--force-if-includes` for extra safety) — this is exactly what fixed your earlier `webflyx` amend situation.

---

## Setting Upstream Tracking

The **first** time you push a new local branch, you need `-u` (or `--set-upstream`) so future `git push`/`git pull` know where to go without arguments:

```bash
git checkout -b feature-x
git push -u origin feature-x   # only needed once
git push                        # works with no args from now on, on this branch
```

Check tracking status anytime:

```bash
git branch -vv
```

---

## Pushing a New Branch vs Deleting One

```bash
git push -u origin feature-x            # create the branch on remote
git push origin --delete feature-x       # remove it from remote
git push origin :feature-x               # older/alternate syntax for delete
```

---

## Push Config Options

|Command|What it does|
|---|---|
|`git config --global push.default simple`|Push only current branch to its same-named upstream (modern default, safest)|
|`git config --global push.autoSetupRemote true`|Automatically set upstream on first push of a new branch — no need for `-u` manually|
|`git config --global push.followTags true`|Always push annotated tags along with commits automatically|

**Recommended for you:**

```bash
git config --global push.autoSetupRemote true
```

This means `git push` alone works even the **first** time you push a brand-new branch — no need to remember `-u`.

---

## Pre-Push Safety Checklist

Before pushing, especially to shared/important branches:

```bash
git status                          # anything uncommitted?
git log origin/main..HEAD --oneline # what commits am I about to push?
git push --dry-run                   # simulate it first
git push
```

---

**One-line definition to remember:**

> `git push` uploads your local commits and moves the remote branch pointer to match — allowed only as a fast-forward by default, and force-pushing (preferably `--force-with-lease`) is the deliberate override for when you've intentionally rewritten history.




[[0 - Git 🍋‍🟩]]