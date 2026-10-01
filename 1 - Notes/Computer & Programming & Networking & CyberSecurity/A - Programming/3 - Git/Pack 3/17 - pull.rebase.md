## `pull.rebase` — Deep Dive

You've seen `pull.rebase` mentioned a few times already as a config flag. Let's build the full mental model of what it actually controls, why it exists, and the mechanics underneath.

---

## Core Intuition First

When you run plain `git pull`, Git has to make a decision: _"I just fetched new commits — how do I combine them with your local commits?"_

There are exactly two ways to combine two diverging lines of commits, and `pull.rebase` is the switch that picks which one `git pull` uses **by default**, so you don't have to type a flag every time.

```
                    merge                              rebase
Local:   A---B---C----M        Local:   A---B---D---C'
Remote:        \--D--/         Remote:  A---B---D
              (D's parent = B)         (C replayed on top of D, new hash)
```

- **Merge** keeps both lines of history exactly as they happened, and joins them with a new commit that has two parents.
- **Rebase** pretends your commits never branched off at all — it detaches them, moves the base forward to include the remote's commits, then **replays** your commits one-by-one on top, generating brand new commit hashes for each.

---

## The Three Possible Values

```bash
git config pull.rebase false     # merge (Git's historical default)
git config pull.rebase true      # rebase
git config pull.rebase merges    # rebase, but preserve merge commits within your local history
```

### `false` — Merge Mode (the original default)

```bash
git pull
# = git fetch + git merge origin/main
```

If diverged, creates a merge commit. Safe, non-destructive — never rewrites a commit that already exists.

### `true` — Rebase Mode

```bash
git pull
# = git fetch + git rebase origin/main
```

If diverged, **removes** your local commits temporarily, fast-forwards your branch to match the remote, then **reapplies** your commits one at a time on top. Each reapplied commit gets a **new SHA-1 hash** — because remember, a commit's hash depends on its parent, and the parent just changed.

### `merges` — Rebase, but Preserve Local Merge Commits

If your local history itself contains merge commits (e.g., you merged another feature branch into your branch before pulling), plain rebase would flatten/linearize everything, destroying that merge structure. `rebase=merges` preserves it while still replaying linearly against the new remote base. This is a more advanced, less commonly needed setting — most solo/simple workflows don't need it.

---

## Why This Matters: The Hash-Rewriting Consequence

This is the part people get bitten by if they don't understand it deeply, and it connects directly back to the object model we covered earlier.

Recall: a commit's SHA-1 is computed from its content **including its parent's hash**. So:

```
commit C  →  parent: B  →  hash = X
```

After rebase, C gets replayed on top of D instead of B:

```
commit C'  →  parent: D  →  hash = Y  (completely different hash, even if the code change is identical)
```

**Consequence:** if you'd already pushed commit C to a remote, and someone else pulled it, then you rebase and get C', pushing now requires `--force-with-lease` — because from Git's perspective, C and C' are two entirely different, unrelated commit objects that happen to produce the same resulting code. This is _exactly_ the mechanism behind your earlier `webflyx --amend` situation — amend is really just "rebase of a single commit."

---

## Setting It Globally

```bash
git config --global pull.rebase true
```

This becomes your default for **every repo** on your machine, unless overridden per-repo or per-branch:

```bash
git config pull.rebase false          # override for just the current repo
git config branch.main.rebase true     # override for just one specific branch
```

Precedence order (most specific wins): `branch.<name>.rebase` → repo-local `pull.rebase` → global `pull.rebase` → Git's hardcoded default (`false`/merge).

---

## Merge vs Rebase on Pull — When to Choose Which

|Scenario|Recommended|Why|
|---|---|---|
|Solo project, your own branches (like `webflyx`)|`rebase` (`true`)|Clean linear history, no merge commit clutter, easier `git log` to read|
|Shared team branch, multiple people pushing|`merge` (`false`)|Rebase would rewrite commits others already have — force-pushing on a shared branch causes real pain for collaborators|
|Public/open-source branch others have forked or pulled|`merge` always|Never rewrite history that's left your machine and entered someone else's|
|Feature branch only you work on, syncing with `main`|`rebase` fine|Standard practice — keeps your branch's history clean before eventually merging into `main`|

**The golden rule underneath all of this (said differently than before, same depth):** rebase is safe exactly as long as the commits being rewritten haven't been seen by anyone else yet. The moment a commit has been pulled by another person or another clone, rewriting it creates a fork in reality — their copy and your new copy both claim to be "the" history, and reconciling that later is messy.

---

## `rebase.autoStash` — The Companion Setting

One friction point with `pull --rebase`: if you have uncommitted changes, Git normally **refuses** to rebase (it would risk overwriting your in-progress edits during the replay).

```bash
git config --global rebase.autoStash true
```

With this on, `git pull` (when configured to rebase) will automatically:

1. Stash your uncommitted changes
2. Perform the rebase
3. Pop the stash back on top

This removes the need to manually `git stash` before every pull when you've got dirty working directory changes — directly useful for your day-to-day workflow.

---

## Seeing It in Action — Concrete Walkthrough

```bash
git config pull.rebase true
```

State before pull:

```
Local (feature):   A---B---C          (C = your uncommitted-turned-committed work)
Remote (origin):   A---B---D---E      (teammate pushed D and E while you worked)
```

```bash
git pull
```

Internally:

```bash
git fetch origin                # downloads D, E — updates origin/feature
git rebase origin/feature        # detaches C, fast-forwards to E, replays C on top
```

Result:

```
Local (feature):   A---B---D---E---C'     (C' = new hash, same content as C)
```

No merge commit. Clean, linear, reads exactly as if you'd written C _after_ D and E existed — which is a small, deliberate "lie" about history, but one most teams consider worth it for readability.

---

## Gotcha: Conflicts During Rebase-Pull Happen Per-Commit

If you have multiple local commits being replayed and more than one conflicts with the incoming changes, you resolve them **one at a time**, not all at once like a merge conflict:

```bash
git pull   # (configured to rebase)
# CONFLICT in commit 1 of 3
# fix, then:
git add <file>
git rebase --continue
# CONFLICT in commit 2 of 3 — repeat
```

This is more tedious than a single merge-conflict resolution, but it means each conflict is scoped to exactly the logical change that commit represents — often easier to reason about than one giant combined diff.

---

**One-line definition to remember:**

> `pull.rebase` is the switch controlling whether `git pull`'s integration step replays your commits on top of the remote (rebase — clean, linear, but rewrites hashes) or joins both histories with a merge commit (merge — safe, non-destructive, preserves exact history) — rebase for your own unshared work, merge once commits have left your machine and entered someone else's.



[[0 - Git]]