

## 1. Core intuition

A Git branch is not a container of commits. It's a **sticky note with a commit hash on it**: a 41-byte file at `.git/refs/heads/<name>` (or a line in `packed-refs`). The commits live in the object database and are kept alive only because something _points_ at them (a branch, tag, HEAD, the reflog, and so on).

So deleting a branch removes the sticky note, not the work. The only danger is that the commits might become **unreachable**, with nothing pointing at them, which makes them invisible and eventually garbage-collectable.

- **`-d`** is the safe delete: "Remove the sticky note only if the commits are already reachable from somewhere that matters, so I can't lose anything."
- **`-D`** is the forced delete: "Remove it anyway, I take responsibility."

In fact, `-D` is just shorthand for `--delete --force`.

## 2. The mechanics

### What "fully merged" means

`-d` checks whether the branch tip is an **ancestor** of a reference commit. It's essentially:

```bash
git merge-base --is-ancestor <branch> <reference>
```

The reference isn't always what you'd expect:

|Situation|Reference used|
|---|---|
|Branch has an upstream (`branch.<name>.merge` is set)|The **upstream** (e.g. `origin/feature`)|
|No upstream|**HEAD** (whatever you currently have checked out)|

The docs state this directly, and it produces the main gotchas below.

### The refusal

```console
$ git branch -d feature
error: the branch 'feature' is not fully merged
hint: If you are sure you want to delete it, run 'git branch -D feature'
```

### The success message is your recovery handle

```console
$ git branch -D feature
Deleted branch feature (was 3f2a9c1).
```

That hash is the old tip. Save it.

### What deletion actually removes

- The ref file (or packed-refs entry)
- The branch's own reflog (`.git/logs/refs/heads/feature`)
- The branch's config section (`branch.feature.remote`, etc.)

It does **not** remove commits, which stay in `.git/objects` until `git gc` prunes unreachable objects (by default after about 2 weeks, via `gc.pruneExpire`).

## 3. Recovering a deleted branch

Because the objects survive, recovery is easy if you act within the prune window:

```bash
# Best case: you saved the hash from the "Deleted branch ... (was X)" message
git branch feature 3f2a9c1

# Otherwise, search the HEAD reflog (it records every place HEAD has been)
git reflog
git branch feature HEAD@{5}

# Last resort: find dangling commits directly
git fsck --lost-found
```

A caveat: the HEAD reflog only helps if you actually _checked out_ the branch at some point. Commits you created on a branch and never touched in a way HEAD recorded can only be found via `fsck`.

## 4. Nuances and gotchas

### Gotcha 1: Squash and rebase merges fool `-d`

This is the most common reason people reach for `-D`. If a PR was merged on GitHub using **squash** or **rebase**, the commits on `main` are _new commits with different hashes_. Your branch tip is not an ancestor of `main`, so:

```console
$ git switch main && git pull
$ git branch -d feature
error: the branch 'feature' is not fully merged
```

The _content_ is in `main`, but Git's check is about commit **ancestry**, not content. Using `-D` here is correct, but verify first:

```bash
# Lists commits on feature whose *patch* isn't in main. "-" means equivalent patch exists.
git cherry -v main feature
```

Lines starting with `-` have a patch-equivalent in `main`. Lines starting with `+` do not, meaning there's genuinely unmerged work. (`git cherry` can miss squashed merges, since a squash combines many patches into one, so for squash merges your real check is the PR status on the hosting platform.)

### Gotcha 2: The result depends on where you're standing

With no upstream configured, `-d` compares against **HEAD**. So:

```bash
git switch some-other-feature
git branch -d feature     # checks merge into some-other-feature, not main!
```

This can refuse a branch that is merged into `main`, or, worse, succeed because it happens to be merged into whatever you're on. Get in the habit of switching to your integration branch first, or use the explicit check:

```bash
git branch --merged main          # list branches merged into main
git branch --no-merged main       # the opposite
```

### Gotcha 3: Upstream vs HEAD disagreement

When an upstream is set, Git checks both and warns on disagreement:

- Merged into upstream, **not** into HEAD: deletes, with `warning: deleting branch 'x' that has been merged to 'refs/remotes/origin/x', but not yet merged to HEAD`
- Merged into HEAD, **not** into upstream (e.g. you merged locally but never pushed the branch): **refuses**, with `not deleting branch 'x' that is not yet merged to 'refs/remotes/origin/x', even though it is merged to HEAD`

### Gotcha 4: Neither flag can delete a checked-out branch

```console
$ git branch -D main     # while on main
error: cannot delete branch 'main' used by worktree at '/path'
```

This includes branches checked out in _other worktrees_. `-D` overrides the merge check, not this protection. Switch away first.

### Gotcha 5: `-d` is not a "reachable from anywhere" check

If your commits are safely reachable from another branch or tag that isn't the reference commit, `-d` still refuses. It is conservative: it only trusts the single reference described above.

### Gotcha 6: Deleting local ≠ deleting remote

```bash
git branch -d feature                  # local branch only
git push origin --delete feature       # actually removes it on the remote
git branch -d -r origin/feature        # removes only your local remote-tracking ref (rarely what you want)
git fetch --prune                      # drop tracking refs for branches deleted on the remote
```

## 5. Practical workflows

**Routine cleanup after merging (safe):**

```bash
git switch main && git pull
git branch --merged main | grep -vE '^\*|main|develop' | xargs -r git branch -d
```

Because this uses `-d`, anything not actually merged is refused rather than destroyed. That's the safety net doing its job.

**Cleanup after squash-merge workflows:** the strategy above won't catch those branches, so a common approach is to delete branches whose upstream is gone:

```bash
git fetch --prune
git branch -vv | awk '/: gone]/{print $1}' | xargs -r git branch -D
```

This uses `-D`, but the "upstream gone" signal (remote branch deleted after PR merge) stands in for the merge check Git can't do. Review the list before running it.

**Abandoning experimental work deliberately:** `-D` is the right tool, but note the printed hash first, or tag it: `git tag archive/experiment feature && git branch -D feature`.

## Summary

||`-d`|`-D`|
|---|---|---|
|Equivalent to|`--delete`|`--delete --force`|
|Merge check|Yes (vs. upstream, else HEAD)|None|
|Can orphan commits|No (by design)|Yes|
|Deletes commits|No|No (they become unreachable, then get pruned later)|
|Bypasses checked-out protection|No|No|

**Mental model to keep:** `-d` asks Git "is this safe?" and `-D` tells Git "I've already decided." Git's definition of "safe" is _ancestry_, which is why squash/rebase workflows and where you're standing both matter so much.




[[Git & Github]]