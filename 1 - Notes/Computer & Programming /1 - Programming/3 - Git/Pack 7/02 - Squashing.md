
Every dev team will have different standards and opinions on how to use Git. Some teams require all pull requests to contain a single commit, while others prefer to see a series of small, focused commits.

If you join a team that prefers a single commit, you will need to know how to "squash" your commits together. To be fair, even if you don't _need_ a single commit, squashing is useful to keep your commit history clean.

---

## 1. Core intuition

**Commits are immutable snapshots, so "squashing" never edits commits. It builds a new commit and moves a ref to it.**

A commit stores a _complete tree_ (a snapshot of the project), a parent pointer, and metadata. It doesn't store a diff. Diffs are computed on demand by comparing a commit's tree to its parent's tree.

That makes squashing easy to reason about:

```
Before:   A ── B ── C ── D ── E      (feature → E)
                \_______________/
                  want these as one

After:    A ── S                      (feature → S)
          S has the same tree as E, but only one commit's worth of history
```

`S` has **the same tree as `E`**. You haven't changed what the project looks like, only how many steps it took to get there. B, C, D, and E still exist in the object database, now unreachable, which is the same situation as after `git branch -D` and the reason recovery works the same way (reflog, `ORIG_HEAD`, about 2 weeks before gc).

This gives you a sanity check for any squash: **the final tree must be identical to the pre-squash tree.**

```bash
git diff ORIG_HEAD HEAD    # should print nothing
```

## 2. The four ways to squash

### A. Interactive rebase (the general-purpose tool)

```bash
git rebase -i HEAD~4          # last 4 commits
git rebase -i main            # everything on this branch since main
```

You get a todo list, **oldest commit at the top**:

```
pick   a1b2c3d Add login form
pick   e4f5a6b Fix typo
pick   7c8d9e0 Handle empty password
pick   1f2e3d4 Fix typo again
```

Edit the verbs:

```
pick   a1b2c3d Add login form
squash e4f5a6b Fix typo
squash 7c8d9e0 Handle empty password
squash 1f2e3d4 Fix typo again
```

**The rule:** `squash` and `fixup` meld a commit into the line **above** it. That's why the first line can't be a squash (there's nothing above it to meld into). The result keeps the **author of the first `pick`**.

|Verb|Commit message|
|---|---|
|`squash` (`s`)|Opens editor with all messages concatenated, so you write the final one|
|`fixup` (`f`)|Discards this commit's message, keeps the upper one|
|`fixup -C`|Discards the upper message and uses _this_ commit's message|
|`fixup -c`|Like `-C`, but opens the editor to tweak it|

You can also **reorder lines** to bring non-adjacent commits together, though that can cause conflicts if they touch the same code.

### B. `reset --soft` (the blunt, fast way)

This is the same trick as in your rebase-accident question, now used deliberately:

```bash
git reset --soft HEAD~4
git commit -m "Add login flow"
```

Or to squash an entire branch regardless of its length:

```bash
git reset --soft $(git merge-base main HEAD)
git commit -m "Add login flow"
```

`--soft` moves the branch ref and leaves the index and working tree alone, so everything from those 4 commits appears as staged changes. You then commit them as one.

**The difference from interactive rebase:** you lose the original authorship and timestamp, because you're making a brand-new commit. To reuse the old commit's message and author:

```bash
git commit -C ORIG_HEAD
```

### C. `git merge --squash` (squash _while_ merging)

```bash
git switch main
git merge --squash feature
git commit
```

This stages the combined changes from `feature` but **does not create a merge commit and does not record `feature` as a parent**. The result is a single ordinary commit on `main`. This is exactly what GitHub/GitLab's "Squash and merge" button does.

### D. Fixup commits and autosquash (the planned approach)

Instead of squashing after the fact, mark commits as corrections _as you make them_:

```bash
git commit --fixup=a1b2c3d        # "this fixes up a1b2c3d"
# ...later:
git rebase -i --autosquash main   # todo list is pre-arranged for you
```

Git names the commit `fixup! <original subject>`, then `--autosquash` automatically moves it under its target and sets the verb to `fixup`. Turn it on permanently:

```bash
git config --global rebase.autoSquash true
```

This is the workflow that makes "clean history" almost free: you commit corrections immediately, and one rebase folds them all in.

## 3. Nuances and gotchas

### Gotcha 1: Squashing rewrites history, so published branches need care

The new commit has a different hash from anything before it. If you've already pushed the old commits, the remote and your local branch have _diverged_, and a normal push is rejected.

```bash
git push --force-with-lease
```

Prefer `--force-with-lease` over `--force`. It refuses to overwrite the remote if someone pushed something you haven't fetched, so you can't accidentally destroy a teammate's commits. Only do this on branches that are yours. Never squash and force-push a shared branch like `main`.

### Gotcha 2: Squash-merge and `git branch -d` (the connection to your first question)

After `git merge --squash feature`, `main` contains the _content_ but **not feature's commits**, and feature's tip is not an ancestor of `main`. So:

```console
$ git branch -d feature
error: the branch 'feature' is not fully merged
```

This is the same issue from the branch deletion topic: Git's safety check is about _ancestry_, and squashing deliberately breaks ancestry. You'll need `-D` (after confirming the PR actually merged), or the `: gone]` workflow.

### Gotcha 3: Squashing destroys granularity

You trade away:

- **`git bisect` precision:** it can only point at the one big commit, not the 30-line change inside it that broke things.
- **`git blame` detail:** every line gets the same squashed message.
- **Selective revert/cherry-pick:** you can't revert just part of the squashed work cleanly.

The usual rule of thumb is to squash _noise_ (WIP, "fix typo," "address review comments") but keep _meaningful, atomic_ commits separate. "Always squash everything" and "never squash" are both defensible team policies, but a mix of curated history and squash-per-PR is common.

### Gotcha 4: Merge commits inside the range

Interactive rebase **flattens merges by default**, dropping merge commits and replaying only the non-merge ones. If your branch contains merges you want to preserve:

```bash
git rebase -i --rebase-merges main
```

Squashing across merges is where things get complex, so it's often simplest to squash the portions on either side separately.

### Gotcha 5: Stacked branches

If `feature-2` is branched off `feature-1` and you squash `feature-1`, `feature-2` still points at the _old_ commits. Newer Git lets one rebase carry dependent branch pointers along:

```bash
git rebase -i --update-refs main
```

### Gotcha 6: Conflicts during a squash

Squashing replays commits, so conflicts can occur (especially if you reordered). You'll resolve them and run `git rebase --continue`. This is the same state from your accidental-commit question, so the same warning applies: **`--continue`, don't `commit`**. Use `reset --soft HEAD~1` if you slip.

### Gotcha 7: Authorship and co-authors

Squashing collapses several people's work into one author. If multiple people contributed, preserve credit with trailers in the final message:

```
Co-authored-by: Name <name@example.com>
```

Hosting platforms recognize this, and `squash` (as opposed to `fixup`) gives you the concatenated messages to harvest these from.

## 4. A safe squash workflow

```bash
git switch feature
git branch backup/feature              # cheap insurance (just a sticky note!)
git rebase -i main                     # squash/fixup as needed
git diff backup/feature HEAD           # must be empty: same final tree
git range-diff main backup/feature HEAD  # optional: compare old vs new series
git push --force-with-lease
git branch -D backup/feature           # when satisfied
```

The empty `git diff` is the key verification, since a correct squash never changes content. If something goes wrong, `git reset --hard backup/feature` (or `git reflog`) puts everything back.

## Summary

|Method|Best for|Keeps original author?|
|---|---|---|
|`rebase -i` with `squash`/`fixup`|Selective, curated cleanup|Yes (first `pick`)|
|`reset --soft` + `commit`|Collapse everything fast|No (unless `commit -C ORIG_HEAD`)|
|`merge --squash`|Landing a branch as one commit|No (you're the committer/author)|
|`--fixup` + `--autosquash`|Planned, continuous cleanup|Yes|

**Mental model:** squashing is a _rewrite_, a new commit with the same final tree and fewer steps. Everything risky about it follows from that: new hashes (so force-push), broken ancestry (so `branch -d` complains), and lost intermediate steps (so bisect and blame get coarser). The old commits remain safe in the reflog until gc.


[[Git & Github]]