

## 1. Core intuition

Picture Git's object database as a **warehouse** and the reflog as a **sticky note on a shelf** saying "this box is still wanted." When the note expires, nobody is protecting the box anymore, but it isn't thrown out immediately. A **janitor** (`git gc`) comes along periodically and discards boxes that no note, label, or branch references.

So "forgotten by the reflog" does not mean "deleted." It means _unprotected_. There are two separate clocks:

1. **The reflog expiry** removes the protective note (90 days for reachable entries, 30 for unreachable ones).
2. **The prune grace period** decides when the janitor actually destroys an unprotected object (`gc.pruneExpire`, default 2 weeks).

Between those two moments, and for as long as `git gc` simply hasn't run, your data is still physically in the warehouse. Your job is to **search the warehouse directly**, not by following labels. The tool for that is `git fsck`.

## 2. Step zero: stop the janitor

Before anything else, protect what's left.

```bash
# Make a full backup of the repository, including .git
cp -a my-repo my-repo-backup

# Prevent automatic garbage collection while you search
git config gc.auto 0
```

Do **not** run `git gc`, `git prune`, or `git reflog expire`. Many ordinary commands (`git pull`, `git commit`, `git merge`) can trigger `gc --auto` in the background, which is why the `gc.auto 0` setting matters.

Then check whether the data is likely still there:

```bash
git count-objects -v
```

Look at `count` (loose objects) and `size-pack`. If the repo is large and old and you've never run `gc` manually, there's a good chance auto-gc has not pruned much.

## 3. The mechanics: reachable, unreachable, dangling

|Term|Meaning|
|---|---|
|**Reachable**|Some branch, tag, stash, or (by default) reflog entry leads to it, so it's safe|
|**Unreachable**|Nothing leads to it, so it's eligible for pruning|
|**Dangling**|Unreachable _and_ nothing else points at it either: the "tip" of an abandoned stretch of history|

If you abandoned three commits A → B → C, then **C is dangling** (the tip), while A and B are merely unreachable, because C points to them as parents. Finding the dangling tip gets you the whole chain.

`git fsck` walks the entire object database and reports these, because it doesn't rely on the reflog.

## 4. Finding lost commits

```bash
git fsck --lost-found
```

This prints lines like:

```
dangling commit 3f9a1c2d8e...
dangling blob   7b2e4f0a11...
```

It also writes the objects into `.git/lost-found/commit/` and `.git/lost-found/other/` so you can inspect them.

Two refinements matter:

```bash
git fsck --no-reflogs --lost-found
```

By default, `fsck` treats reflog entries as references. `--no-reflogs` shows objects that _only_ the reflog was keeping alive. After expiry this makes little difference, but it's useful earlier.

```bash
git fsck --unreachable --no-reflogs | grep commit
```

`--unreachable` lists everything unprotected, not only the tips, which is noisier but catches middle-of-chain commits when the tip is gone.

### Triage: which commit is the one I want?

Raw hashes tell you nothing, so print dates and subjects:

```bash
for c in $(git fsck --no-reflogs --lost-found 2>/dev/null | awk '/dangling commit/ {print $3}'); do
  git log -1 --format='%h  %ad  %an  %s' --date=short "$c"
done | sort -k2
```

Then inspect candidates:

```bash
git show <hash>              # what changed in this commit
git log --oneline <hash>     # the chain behind it (its ancestors)
git diff HEAD <hash>         # how it differs from today
```

### Revive it

```bash
git branch rescued <hash>
```

That's all. A branch label is the "sticky note" again, and the commit and its entire ancestry are reachable and protected. You can then `git switch rescued`, cherry-pick from it, or merge it.

## 5. Finding lost _file contents_ (blobs)

Sometimes you don't have a commit, only file contents. This happens when you ran `git add` (staging writes the file into the object database as a **blob**) but never committed, then lost the work with `reset --hard` or `checkout .`.

Blobs have no filename or timestamp inside them. A blob is raw content only, so you search by content:

```bash
git fsck --lost-found
grep -rl "someDistinctiveMethodName" .git/lost-found/other/
```

Or without relying on `lost-found`:

```bash
for b in $(git fsck --unreachable --no-reflogs | awk '/blob/ {print $3}'); do
  if git cat-file -p "$b" | grep -q "someDistinctiveMethodName"; then
    echo "== $b"
  fi
done
```

Then read it and save it:

```bash
git cat-file -p <blob-hash> > recovered-TaskService.java
```

**Limits:** only content that was **staged at least once** exists as a blob. Edits you made in the editor and never ran `git add` on were never in Git's database at all.

## 6. Lost stashes

Dropped or cleared stashes are also just commits (a stash is a merge commit with two or three parents), so they appear as dangling commits. To spot them:

```bash
git fsck --unreachable --no-reflogs | awk '/commit/ {print $3}' \
  | xargs git log --merges --no-walk --format='%h %ad %s' --date=iso
```

Stash commits usually have messages beginning with `WIP on` or `On <branch>:`. Restore with `git stash apply <hash>`.

## 7. If `fsck` finds nothing: the objects were really pruned

Possible reasons:

- `git gc --prune=now` or `git reflog expire --expire=now --all` was run (by you or a tool).
- Auto-gc ran after the grace period elapsed.
- The commit was only ever in a different clone, never in this one.

Git itself can't help once the bytes are gone, but **other copies** often exist. Check these, roughly in order of likelihood:

1. **The remote.** If you ever pushed that branch, the commits live on the server. `git fetch origin` and `git log origin/<branch>`. If a branch was deleted on the remote, hosting services often keep the commits for a while. On GitHub, pull requests keep their commits under `refs/pull/<n>/head`, even after the branch is deleted, and you can fetch them: `git fetch origin refs/pull/<n>/head:recovered-pr`. If you know the exact hash, `git fetch origin <hash>` can work on some servers, and hosting support can sometimes restore a dangling commit by hash.
2. **Other clones**, such as a teammate's checkout, a CI runner's workspace, or a second machine. Their reflogs are independent of yours, so a commit you lost may be safe in theirs.
3. **Your editor's local history.** If you use IntelliJ IDEA for Java, **Local History** (right-click in the project tree → _Local History → Show History_) records file states independently of Git, and it is excellent for uncommitted work that Git never saw. VS Code has the _Timeline_ view for the same purpose.
4. **System backups**, such as Timeshift or an rsync backup, if you run them on Debian.
5. **Build outputs and artifacts**, such as compiled `.class` files or a JAR in `target/`. These can be decompiled to reconstruct lost Java source. That's a last resort and loses comments and formatting.
6. **Filesystem-level recovery.** Loose objects are small files under `.git/objects/xx/...`. If one was deleted, undelete tools can sometimes find it on ext4, but success drops fast once the disk is reused. Stop writing to the disk if you go this route.

## 8. Nuances and gotchas

- **Packed objects.** After a `gc`, loose objects get compacted into `.git/objects/pack/`. Unreachable objects inside packs are handled differently by Git version. Since Git 2.37, `gc` can keep them in a **cruft pack** with recorded modification times, so they still expire on the same schedule, but they remain findable by `fsck` until pruning. In older versions they may be exploded back into loose files first. Either way, `fsck` sees through packs, so don't worry about the format.
- **The grace period uses file mtime**, not the commit date. An old commit that was only recently orphaned can survive longer than you'd expect, because the clock starts when it became loose or unreachable.
- **`fsck` can be slow** in big repos, and the output can be huge. Redirect to a file: `git fsck --lost-found > fsck.txt 2>&1`.
- **Dangling does not mean useful.** Every amend, rebase, and abandoned experiment leaves dangling commits. Expect a lot of noise, which is why the date and subject triage in section 4 is important.
- **Blobs can be huge in number.** Narrow by searching for a distinctive string rather than reading them all.
- **Hash prefixes work.** `git show 3f9a1c2` is enough if it's unambiguous.

## 9. Prevention, so this never needs a miracle

```bash
# Keep unreachable objects and reflog entries far longer
git config --global gc.reflogExpire 1.year
git config --global gc.reflogExpireUnreachable 180.days
git config --global gc.pruneExpire 1.month
```

And the cheap habits that matter more than any config:

- `git branch backup-before-rebase` before risky operations. It costs nothing.
- Push work-in-progress branches to the remote regularly. A remote is a free off-site backup.
- Commit early and often locally; you can squash later.

## 10. Quick decision map

|Situation|Best move|
|---|---|
|Lost commits, reflog expired, `gc` never run|`git fsck --lost-found`, triage, `git branch rescued <hash>`|
|Lost staged-but-uncommitted file|`git fsck` blob search by content|
|Lost never-staged edits|IDE local history, backups|
|`gc --prune=now` was run|Remote, other clones, teammates, CI|
|Branch deleted on GitHub|PR refs (`refs/pull/N/head`), or hosting support with the hash|




[[Git & Github]]