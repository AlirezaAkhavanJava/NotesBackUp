

## 1. The core intuition

Imagine your repository is a house, and `git log` is the **guest book**: it lists only the people (commits) who are currently "inside" your branch's history. Now imagine there's also a **security camera log** at the front door that records _every time you moved_: "walked into room A," "jumped to room B," "tore down a wall and rebuilt it." The camera doesn't care whether the rooms still exist today. It just records where you were standing, in order.

That camera log is the reflog.

- **`git log`** answers: _"What is the history that leads to where I am now?"_
- **`git reflog`** answers: _"Where has my `HEAD` actually been, and in what order?"_

These are different questions. If you reset a branch backwards, `git log` forgets the commits you discarded. The reflog doesn't, and that's why it's the "undo button" for most Git disasters.

## 2. The mental model: commits are never edited, only pointed at

Two facts make the reflog make sense:

1. **Commits are immutable.** A commit is identified by a hash of its contents. You can't change a commit; "amending" or "rebasing" actually creates _new_ commits.
2. **Branches are just movable labels.** `main` is a tiny file containing one commit hash. When you commit, reset, or rebase, Git simply overwrites that hash with a different one.

So when you "lose" work, usually the commits still exist in Git's object database. What's lost is the **label pointing at them**. They've become _unreachable_, like a house with no street address. The reflog is a diary of the addresses you've used, so you can find your way back.

## 3. What it actually records

Each entry is created whenever a ref (`HEAD`, or a branch) is updated:

```
a1b2c3d HEAD@{0}: commit: Add login endpoint
e4f5a6b HEAD@{1}: checkout: moving from main to feature/auth
9c8d7e6 HEAD@{2}: reset: moving to HEAD~2
```

Reading one line: `a1b2c3d` is the commit `HEAD` pointed to _after_ the action; `HEAD@{0}` is its position (0 = now, 1 = one move ago); the rest is a description of the action (commit, checkout, merge, rebase, reset, pull, cherry-pick, amend...).

**There isn't one reflog, there are many.** Git keeps a separate reflog per ref:

- `HEAD`'s reflog (what plain `git reflog` shows), stored in `.git/logs/HEAD`
- Each branch's reflog, stored in `.git/logs/refs/heads/<branch>`

View a branch's log with `git reflog show feature/auth`. This distinction matters: the `HEAD` reflog records _everything you did while checked out anywhere_, while a branch reflog records only _that branch's own movements_. If you deleted a branch, its own reflog is deleted with it, but the `HEAD` reflog still remembers the commits.

## 4. Referring to entries: two different syntaxes

This confuses almost everyone at first.

|Syntax|Meaning|
|---|---|
|`HEAD@{2}`|Where `HEAD` was **2 moves ago** (count-based)|
|`HEAD@{yesterday}` or `main@{2.hours.ago}`|Where it was at that **point in time** (time-based)|
|`HEAD~2`|**Two commits before** `HEAD` in _ancestry_ (history-based)|

`@{n}` walks through _time/actions_, `~n` walks through _parent links in the commit graph_. After a reset or checkout these can point to totally different commits. Also: `@{n}` positions **shift** with every new action you take, because entry 0 is always the newest. So run `git reflog` right before using a position, or use the hash directly, which never changes.

Time-based syntax relies on the **local clock** of your machine's reflog records, so it's about _when you did it here_, not when the commit was authored.

## 5. Recovery recipes, with the "why"

**Undo a `git reset --hard`**

```bash
git reflog                  # find the entry just before "reset: moving to ..."
git reset --hard HEAD@{1}   # or the hash itself
```

_Why it works:_ `reset --hard` moved the branch label backwards and rewrote your working files, but the discarded commits remain in the object database. You're just re-pointing the label.

**Recover a deleted branch**

```bash
git reflog
git branch recovered a1b2c3d
```

I use `git branch name <hash>` rather than `checkout -b` here because it only creates the label without switching. Either works.

**Undo a bad rebase**

```bash
git reflog      # find the last entry BEFORE "rebase (start)"
git reset --hard <that-hash>
```

_Why:_ a rebase creates brand-new copies of your commits and moves the branch to them. The originals are untouched, just unlabeled. There's also a handy shortcut, **`ORIG_HEAD`**, which Git sets before risky operations like reset, merge, and rebase: `git reset --hard ORIG_HEAD` often undoes the last one instantly. It's overwritten by the next such operation, so it's short-lived.

**Recover work from a detached HEAD**

If you committed while in "detached HEAD" state and then checked out another branch, no branch points at those commits. The `HEAD` reflog still lists them (`commit: ...` entries followed by a `checkout: moving from <hash> to main`).

**Find a commit you amended**

`git commit --amend` creates a new commit and abandons the old one. The old version shows up in the reflog. Recover its content with `git show <old-hash>` or `git cherry-pick <old-hash>`.

## 6. Nuances, limits, and gotchas

**It is local-only.** Reflogs are never pushed or fetched. A fresh `git clone` has an almost empty reflog. If your laptop's repo is destroyed, so is the safety net. (A _bare_ server repository typically doesn't keep reflogs either, since `core.logAllRefUpdates` defaults to false there.)

**It expires.** Git must eventually clean up. Defaults:

- `gc.reflogExpire`: **90 days** for entries whose commits are still reachable
- `gc.reflogExpireUnreachable`: **30 days** for entries pointing at unreachable commits

After expiry, `git gc` can prune the orphaned objects for real, and then they're gone. Unreachable objects also have a separate grace period before pruning (`gc.pruneExpire`, 2 weeks by default). You can inspect or change these with `git config`.

**It only tracks committed (or stashed) state.** The reflog records ref movements. Changes that were never committed or staged have no commit to point at. A `git reset --hard` or `git checkout -- .` that wipes uncommitted edits is generally unrecoverable via reflog. One partial rescue: files you ran `git add` on were written as blob objects, so `git fsck --lost-found` can sometimes find them. Treat that as a last resort, not a plan.

**Stash has its own reflog.** `git stash list` is literally the reflog of `refs/stash`. Dropped stashes can sometimes be found with `git fsck --unreachable | grep commit`.

**Pulling and fetching are logged too.** You'll see lines like `pull: Fast-forward`. A `git pull` that merged something unexpected is often undone with `git reset --hard HEAD@{1}`, _provided you have no uncommitted work you care about_, since `--hard` discards it.

**`reflog` is a shorthand.** `git reflog` is really `git reflog show`, which is `git log -g --abbrev-commit --pretty=oneline`. So you can use the full `git log -g` for richer output, such as including dates and authors:

```bash
git log -g --date=iso
git reflog --date=relative
```

## 7. Related concepts

- **Reachability & garbage collection:** a commit is "alive" if some ref (branch, tag, stash, reflog entry) can reach it. The reflog counts as a reference for this purpose, which is _why_ abandoned commits survive for weeks instead of vanishing immediately.
- **`git fsck --lost-found`:** the deeper tool. When the reflog has expired or doesn't help, it scans the whole object database for dangling commits and blobs.
- **`ORIG_HEAD`, `FETCH_HEAD`, `MERGE_HEAD`:** special refs Git sets during operations; useful for quick undoes.
- **`git reset` vs `git revert`:** `reset` rewrites where a branch points (and the reflog lets you undo it); `revert` adds a _new_ commit that cancels an old one, which is the safe choice for shared history.

## 8. Practical habits

1. Before a risky operation (rebase, filter-branch, hard reset), note the current hash, or create a throwaway branch: `git branch backup-before-rebase`. It costs nothing.
2. When something goes wrong, **stop and run `git reflog` before doing anything else.** Further actions push the useful entry down but don't erase it.
3. Don't run `git gc --prune=now` or `git reflog expire --expire=now --all` unless you're certain you want the safety net gone.

[[Git & Github]]