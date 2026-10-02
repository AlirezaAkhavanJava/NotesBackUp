

**Core principle:** _A fork is a snapshot, frozen the moment you created it. Without a deliberate habit of syncing, it only gets staler — so syncing from `upstream` isn't a one-time setup step, it's a recurring discipline you build into how you start every new piece of work._

---

## The Pattern, Named

```
fetch upstream → merge into local main → push to origin → branch from there
```

This is the loop. Every single time, before starting anything new.

---

## Step 1 — One-Time Setup (Done Once, Per Clone)

```bash
git clone https://github.com/YourUsername/project.git
cd project
git remote add upstream https://github.com/OriginalOwner/project.git
```

---

## Step 2 — The Recurring Habit (Done Every Time, Before New Work)

```bash
git switch main
git fetch upstream
git merge upstream/main        # or: git rebase upstream/main for linear history
git push origin main             # keep YOUR fork's main current on GitHub too
```

**The discipline to internalize:** never branch off a `main` you haven't just synced. Treat your local `main` as _always suspect_ until you've run this sequence — the moment before you start something new is exactly when staleness causes the most damage (stale base → conflicts later, when you least want to deal with them).

---

## Step 3 — Branch From the Freshly-Synced Base

```bash
git switch -c feature-x
```

Now your feature branch inherits an up-to-date starting point, instead of silently building on top of code that's weeks or months behind.

---

## Why This Is a _Style_, Not Just a Command Sequence

The commands alone don't make this valuable — the habit does. Three principles underneath it, worth generalizing beyond just forks:

|Principle|Why it matters here|Where else it applies|
|---|---|---|
|**A copy is only as good as its last sync**|Your fork doesn't "stay current" on its own — it's frozen the instant you stop checking|Any cached/mirrored data — local Docker images, vendored dependencies, cloned docs|
|**Sync the trunk before branching, not after**|Catching staleness _before_ you've invested hours in a branch is cheap; catching it _after_, via conflicts, is expensive|Rebasing a long-lived feature branch onto `main` periodically — same principle, same payoff|
|**Keep the "shared" line pristine**|By never committing directly to `main`, syncing is always a clean fast-forward — no merge conflicts _in the syncing itself_|This is the rule from the earlier fork deep-dive: never work directly on `main`, only on branches|

---

## The Improved Version — Making the Habit Harder to Forget

Same upgrade pattern as the `.git/info/exclude` improvement earlier: don't rely on memory, automate the repeatable part.

```bash
#!/usr/bin/env bash
# sync-fork.sh — run before starting any new branch
git switch main
git fetch upstream
git merge upstream/main
git push origin main
echo "Fork synced. Safe to branch now."
```

```bash
bash sync-fork.sh
git switch -c new-feature
```

One command, one mental checkpoint, every time — instead of trusting yourself to remember three separate commands correctly, in order, every single time you start something new.

---

**One-line summary to remember:**

> The style isn't "add an upstream remote" — that's just the prerequisite. The actual discipline is treating your fork's `main` as perpetually stale until proven otherwise, syncing it _before_ every new branch rather than reactively after a conflict forces you to, and keeping `main` itself untouched so that sync is always a trivial, conflict-free fast-forward.


[[0 - Git]]