 

> never rebase a public branch. Do rebase your own private branch onto the public one.**

## Why the direction matters

Rebasing rewrites commit history — it takes your commits and replays them on top of a new base, generating brand-new commit hashes for each one.

- **Your private/feature branch** — nobody else has it, so rewriting its history is harmless. Nobody's work depends on those old commits.
- **A public branch** (`main`, `develop`, anything others have pulled) — other people's local copies and any branches they built on top are now based on commits that no longer exist upstream. Next time they pull, they get a tangled mess of duplicate commits and merge conflicts, or `git pull` outright refuses.

This is sometimes called **the Golden Rule of Rebasing**: never rebase commits that exist outside your own repo, that other people may have based work on.

## What you actually do

You rebase your feature branch _onto_ the public branch — to catch up with what's changed upstream, before you merge or push.

```bash
git checkout feature/login-form
git fetch origin
git rebase origin/main
```

This replays your feature commits on top of the latest `main`, giving you a clean, linear history — as if you'd started your branch just now, from the current tip of `main`.

```
Before:
main:     A---B---C
                \
feature:         D---E

After rebase:
main:     A---B---C
                    \
feature:             D'---E'
```

## The one place it gets murkier: your own already-pushed branch

If you pushed your feature branch to the remote (so it's "public" in the sense that it's backed up / others _could_ see it) and you rebase it locally, you'll need a **force push** to update the remote:

```bash
git push --force-with-lease
```

`--force-with-lease` (not plain `--force`) is the safety net — it refuses to overwrite the remote if someone else pushed to that branch since you last fetched.

**Rule of thumb:** if you're the only one who has ever pulled that branch, force-pushing after a rebase is fine. If a teammate is also committing to it, rebasing-and-force-pushing is the same golden-rule violation as rebasing `main` — coordinate with them or use a merge instead.

---

**You run `rebase` while checked out on your feature branch**, pulling in the public branch (`main`) as the target you're rebasing _onto_:

```bash
git checkout feature/login-form   # you're ON the feature branch
git fetch origin
git rebase origin/main            # replay feature commits on top of main
```

You never check out `main` and rebase it onto your feature branch — that would rewrite the public branch's history, which is the thing to avoid.

So the mental shortcut:

|You're on...|Rebase onto...|Safe?|
|---|---|---|
|your feature branch|`main`|✅ yes — this is the normal workflow|
|`main`|your feature branch|❌ no — rewrites public history|

One more nuance worth knowing since you're doing this on a real repo: if your feature branch only exists locally (never pushed), rebase freely, no downsides. If you already pushed it and a rebase changes its commits, you'll need `git push --force-with-lease` to update the remote — and that's only safe if you're the sole person working on that branch.

---

## The Golden Rule of Rebasing

> **Never rebase a branch that others are working on (a "public" branch).**
> **Do rebase your own private/personal branch to keep it up to date.**

## Feature Branch

You're on `feature/my-work` (your personal branch). Meanwhile, `main` (public, shared) has moved forward with new commits.

**The right move:** rebase your feature branch *onto* main.

```bash
# You are on your feature branch
git checkout feature/my-work

# Fetch the latest main
git fetch origin

# Replay your commits on top of the latest main
git rebase origin/main
```

### What this does

```
Before:
main:     A---B---C---D---E
                   \
feature:            F---G---H

After rebase:
main:     A---B---C---D---E
                           \
feature:                    F'---G'---H'
```

Your commits (F, G, H) are replayed as new commits (F', G', H') on top of the latest main. Your feature branch now looks like it was branched off the *current* tip of main.

### Why this is good

- **Linear history** — no messy merge commits
- **Easy to review** — your PR shows only your changes
- **Safe** — nobody else depends on your feature branch

### After rebasing, you must force-push

```bash
git push --force-with-lease origin feature/my-work
```

Use `--force-with-lease` (not plain `--force`) so you don't clobber commits if someone else pushed to your branch in the meantime.

## Why NOT to rebase `main`

`main` is public. Other people have based their work on it. If you rewrite its history:

- Everyone else's local `main` diverges from the remote
- Their feature branches now have broken ancestry
- Pulling becomes a nightmare

If you need to update `main`, use **merge** (or fast-forward), never rebase:

```bash
git checkout main
git pull   # merge or fast-forward, never rebase
```

## The Mental Model

| Branch type | Rebase? | Why |
|---|---|---|
| Your feature branch | ✅ Yes | Only you use it; rewriting is safe |
| `main` / `develop` / shared | ❌ No | Others depend on its history |
| A teammate's branch | ❌ No | Not yours to rewrite |

**Rule of thumb:** *Rebase your own branch onto the public branch. Never rebase the public branch onto your own.*

## A Common Workflow (the "rebasing workflow")

```bash
# 1. Work on your feature
git checkout -b feature/login
# ... commits ...

# 2. Main moves forward
git fetch origin

# 3. Rebase your work onto latest main
git rebase origin/main

# 4. Resolve any conflicts, then continue
git rebase --continue

# 5. Force-push your updated feature branch
git push --force-with-lease origin feature/login

# 6. Open / update the PR — clean, linear diff
```

So yes — **on the feature branch, rebase. On `main`, never.** You've got it exactly right.


---

# Rebase alters **your current branch**, not the target.

This is the single most misunderstood thing about `git rebase`, so let's be precise.

## The command

```bash
git checkout feature/login      # you are ON your branch
git rebase main                 # "rebase onto main"
```

You are standing on `feature/login`. **`feature/login` is what gets rewritten.** `main` is only read as the new base — it is untouched.

## Visualized

```
BEFORE:
main:     A---B---C---D---E
                   \
feature:            F---G---H   ← you are here

AFTER `git rebase main`:
main:     A---B---C---D---E          ← UNCHANGED
                           \
feature:                    F'---G'---H'   ← rewritten, you are still here
```

- `main` still points at `E`. Same commits. Same SHAs.
- `feature/login` now points at `H'` — brand-new commits with new SHAs.
- Your working directory is still on `feature/login`.

## The grammar of the command

This trips people up because English is ambiguous:

> "Rebase my feature branch **onto** main"

Read it as:

> "Take **my feature branch** and move **its** commits so they sit on top of main."

The **subject** of the rewrite is the branch you're on (the one named *before* "onto"). The word after "onto" is just the destination — a reference point.

## A clearer mental phrasing

Instead of "rebase feature onto main," think:

> **"Replant my branch on top of main."**

The plant (your branch) moves. The soil (main) stays put.

## What if you want to change main?

You don't rebase main onto anything. If main needs to absorb your work, you **merge** (or fast-forward), and even then the operation is run *from* main:

```bash
git checkout main
git merge feature/login     # main moves forward to include your work
```

That's a different operation with a different direction of change. It creates a new commit on `main` (or fast-forwards), and it never rewrites history.

## Cheat sheet

| You run… | Branch rewritten | Branch untouched |
|---|---|---|
| `git rebase main` (on feature) | `feature` | `main` |
| `git rebase feature` (on main) | `main` ⚠️ | `feature` |
| `git merge feature` (on main) | `main` (new commit) | `feature` |

Notice row 2 is the dangerous one — if you're on `main` and run `git rebase feature`, you'd rewrite `main`. That's the exact anti-pattern from the previous answer.

## Quick sanity check before you run it

```bash
git branch --show-current      # which branch am I on?
```

If that prints your feature branch → safe to rebase.
If it prints `main` → **stop**, don't rebase.

So to answer you directly: **yes.** "Rebase my feature branch onto main" means *my feature branch gets rewritten; main does not.* You've got the model exactly right.

[[0 - Git 🍋‍🟩]]