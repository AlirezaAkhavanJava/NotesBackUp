

`git pull` is a **combined command** that does two things in sequence:

```
git pull = git fetch + git merge (or git rebase)
```

It downloads new commits from a remote **and** immediately integrates them into your current local branch — in one step, instead of the two-step fetch-then-merge process covered earlier.

---

## What Happens Internally

```bash
git pull origin main
```

is exactly equivalent to:

```bash
git fetch origin
git merge origin/main
```

1. **Fetch phase** — downloads new objects, updates `origin/main` (remote-tracking branch)
2. **Merge phase** — merges `origin/main` into your current local branch, creating a merge commit if histories diverged

---

## Pull with Merge vs. Pull with Rebase

By default, `git pull` uses **merge**. But you can make it use **rebase** instead — replaying your local commits on top of the remote's, instead of creating a merge commit.

||`git pull` (merge, default)|`git pull --rebase`|
|---|---|---|
|History shape|Creates a merge commit if diverged|Linear — no merge commit|
|Local commits|Kept as-is, combined via merge|Rewritten (new hashes) on top of remote|
|Good for|Shared branches, preserving exact history|Solo work, keeping history clean|
|Risk|"Merge commit spam" on active branches|Rewrites local commit hashes — don't rebase pushed/shared commits|

```bash
git pull --rebase origin main
```

---

## Common `pull`-Related Commands

|Command|What it does|
|---|---|
|`git pull`|Fetch + merge from the tracked upstream branch|
|`git pull origin main`|Fetch + merge explicitly from `origin`'s `main` branch|
|`git pull --rebase`|Fetch + rebase instead of merge|
|`git pull --no-rebase`|Force merge behavior (overrides any rebase config)|
|`git pull --ff-only`|Only pull if it can fast-forward — refuses if histories diverged (safest option, no surprise merge commits)|
|`git pull --no-commit`|Fetch + merge, but stop before creating the merge commit (lets you review first)|
|`git pull --all`|Pull from all configured remotes|
|`git pull -v`|Verbose output|
|`git config pull.rebase true`|Make rebase the **default** behavior for all future `git pull` (no need to type `--rebase` each time)|
|`git config pull.ff only`|Make fast-forward-only the default (recommended for safety on solo projects)|

---

## Related Setup Commands (Tracking)

For plain `git pull` (no arguments) to work, your local branch needs to know **which remote branch to pull from** — this is called the **upstream/tracking branch**.

|Command|What it does|
|---|---|
|`git push -u origin main`|Push AND set `main` to track `origin/main` (do this once per branch)|
|`git branch -u origin/main`|Set tracking for an existing local branch, without pushing|
|`git branch -vv`|Show which remote branch each local branch is tracking|

Once tracking is set, `git pull` alone (no args) knows exactly where to fetch/merge from.

---

## Why `--ff-only` Is Worth Knowing

```bash
git pull --ff-only
```

This refuses to pull if it would require a merge commit (i.e., if you have local commits the remote doesn't have). Instead, it just errors out and tells you to handle the divergence manually (rebase, merge, or reset).

Many experienced users set this as their **default**, since it prevents accidental "surprise" merge commits from ever being created automatically:

```bash
git config --global pull.ff only
```

---

## Visual: What Pull Actually Changes

```
Before pull:
  main          → commit A
  origin/main    → commit B  (new commits exist upstream)

After git pull (merge):
  main          → commit C  (merge commit combining A and B)
  origin/main    → commit B

After git pull --rebase:
  main          → commit A' (your commit A replayed on top of B — new hash!)
  origin/main    → commit B
```

---

**One-line definition to remember:**

> `git pull` = fetch + integrate in one step — by default via merge, but rebase is often preferred for cleaner, linear history on solo or feature-branch work.




[[0 - Git 🍋‍🟩]]