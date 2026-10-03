

**Yes, your understanding is correct.** The reflog has no power over changes that were never committed. One refinement makes the picture complete: it's not only about `HEAD`, it's about _what the reflog is_.

## 1. Core intuition

The reflog is a **diary of pointer movements**, not a **camera watching your files**.

Each entry says "this ref (a label like `HEAD` or `main`) used to point at commit X, now it points at commit Y." Every entry therefore needs a **commit hash** to point at. If your work was never wrapped in a commit, there is nothing for an entry to reference, so nothing gets written.

A useful analogy: the reflog is a **library checkout ledger**. It records which books were borrowed and returned. If you scribbled notes on a loose sheet of paper and then threw it away, the ledger has no idea that sheet ever existed. It only tracks books.

## 2. The three layers of your work

Your files can be in one of three states, and Git "sees" each differently:

|State|Where it lives|Does Git store it?|Reflog entry?|
|---|---|---|---|
|**Committed**|Object database, referenced by a commit|Yes, permanently (until gc)|Yes, when a ref moves to it|
|**Staged** (`git add`)|Index, and the file content is written as a **blob** object|Yes, as an orphan-able blob|**No**|
|**Working tree only** (edited, not added)|Just a normal file on disk|**No**|**No**|

The reflog only ever cares about the first row.

## 3. What each loss scenario means

**Edited but never added, then wiped** (`git checkout -- file`, `git restore file`, `git reset --hard`, or saving over it):  
Git never stored those bytes. The reflog can't help and neither can `git fsck`. Recovery must come from outside Git: your IDE's local history, editor backups or swap files, Timeshift or other system backups.

**Staged (`git add`) but never committed, then wiped:**  
The content was written into `.git/objects` as a blob at the moment you ran `git add`. No ref points to it, so the reflog is blind, but **the data physically exists** until gc prunes it. Recover with:

```bash
git fsck --lost-found
grep -rl "distinctiveString" .git/lost-found/other/
```

Blobs carry no filename or date, so you search by content. Only the version from the _last_ `git add` of that file exists.

**Untracked files deleted by `git clean`, or any `rm`:**  
If they were never `git add`ed, Git never knew them. Same as the first row.

**Stashed (`git stash`), then dropped:**  
A stash is secretly a commit, so it has hashes, and the stash has its own reflog (`git stash list` _is_ that reflog). A dropped stash is a dangling commit and can be found with `git fsck --unreachable | grep commit`.

**Committed, then branch deleted, reset, or rebased:**  
This is where the reflog shines. The commit exists, and a ref moved, so there's an entry.

## 4. Why it works this way

Git is a **content-addressed snapshot store**, not a continuous file-watcher. It never runs in the background monitoring your editor. It only acts when you invoke a command. There are exactly two commands that put your content into the database: `git add` (creates blobs) and `git commit` (creates a tree and commit from the index). Anything before those steps lives only on your disk, outside Git's knowledge.

The reflog is built on top of that. It's a small side-log updated whenever a _ref_ changes, so its scope is inherently limited to things that have been committed (or at least turned into commits, like stashes).

## 5. Nuances and refinements

- **Not only `HEAD`.** Each branch has its own reflog too, plus `refs/stash`. But all of them are logs of _ref movements to commits_, so the conclusion is identical.
- **`git add` doesn't log, even though it stores data.** This asymmetry surprises people. The blob is stored, but no ref moved, so no reflog line exists. That's why `fsck`, not `reflog`, is the tool for staged-but-lost content.
- **Only the latest staged version survives per file.** If you `git add` a file, edit it, and `git add` again, the first blob becomes an unreferenced orphan (recoverable via fsck until pruned), while the second is the one in the index.
- **Reflog expiry doesn't affect staged blobs differently.** They're subject to the prune grace period (`gc.pruneExpire`, two weeks by default).
- **A commit does not have to be on a branch to be logged.** Detached-HEAD commits are logged in the `HEAD` reflog, which is why they're recoverable.

## 6. Habits that turn this limitation into a non-issue

1. **Commit early, locally, even if messy.** You can squash or amend later, and committing makes the reflog your safety net. A commit is the cheapest insurance Git offers.
2. **Use `git stash` before risky operations** (`reset --hard`, `checkout`, `clean`). It turns uncommitted work into a commit with its own reflog.
3. **Use `git add` as a cheap checkpoint** for work you're unsure about. It isn't tracked by the reflog but it does create a recoverable blob.
4. **Dry-run destructive commands.** `git clean -n` previews deletions, and `git diff` shows what `reset --hard` or `restore` would discard.
5. **Rely on your IDE's local history** for the unstaged gap. In IntelliJ, right-click a file and choose _Local History → Show History_.

## 7. Summary

|Situation|Reflog helps?|What helps instead|
|---|---|---|
|Committed, then lost the branch/commit|Yes|`git reflog`|
|Staged, then wiped|No|`git fsck --lost-found` (blobs)|
|Dropped stash|Not directly|`git fsck --unreachable`|
|Never added, then wiped|No|IDE history, backups|

So your statement is right: the reflog tracks where refs pointed, and it can only recover work that had been committed. If you'd like, I can show you a short experiment you can run in a scratch repo to see each of these cases happen with your own eyes.

[[Git & Github]]