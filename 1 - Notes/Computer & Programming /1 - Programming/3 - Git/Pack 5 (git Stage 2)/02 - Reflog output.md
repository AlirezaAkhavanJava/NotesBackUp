
# Reading `git reflog` output

## 1. Core intuition

The reflog is a **flight recorder**. Each line is one event: "at this moment, this action happened, and afterwards the pointer was here." You read it like a story, **bottom to top**, because the newest event is at the top and the oldest at the bottom.

Every line answers three questions:

1. **Where am I now?** (the hash)
2. **How far back in time is this?** (the `HEAD@{n}` position)
3. **What did I do to get here?** (the action text)

## 2. Anatomy of one line

```
8d4e0b7 HEAD@{1}: commit: Fix null check in TaskService
└──┬──┘ └──┬───┘  └─┬──┘ └──────────┬──────────────┘
 hash   position  action        detail
```

|Part|Meaning|
|---|---|
|`8d4e0b7`|Abbreviated commit hash that `HEAD` pointed to **after** this action finished|
|`HEAD@{1}`|Position in the log: `{0}` is the most recent, higher is older. Numbers shift whenever you do something new|
|`commit`|The **action type** (what kind of operation moved `HEAD`)|
|`Fix null check...`|The **detail**: commit message, branch names, or the argument you gave the command|

**The most important rule: the hash is the state _after_ the action, not before.** A `reset` line shows the commit you landed on, not the commit you left. To find what you had _before_ an action, look at the line **below** it (the older one).

## 3. A worked example, read as a story

```
c91d5a0 HEAD@{0}: reset: moving to HEAD~2
8d4e0b7 HEAD@{1}: commit: Fix null check in TaskService
2b7c1fe HEAD@{2}: commit: Add TaskController
c91d5a0 HEAD@{3}: checkout: moving from main to feature/tasks
c91d5a0 HEAD@{4}: pull: Fast-forward
e11f2c8 HEAD@{5}: commit (initial): Initial commit
```

Reading from the **bottom up**:

1. `{5}` You made the first commit in the repo.
2. `{4}` You ran `git pull` and it fast-forwarded `main` to `c91d5a0`.
3. `{3}` You switched from `main` to a new branch `feature/tasks`. The hash is still `c91d5a0`, because switching branches doesn't change the commit, only which label `HEAD` follows. That's why `{4}` and `{3}` show the same hash.
4. `{2}` You committed "Add TaskController", producing `2b7c1fe`.
5. `{1}` You committed again, producing `8d4e0b7`.
6. `{0}` You ran `git reset HEAD~2`, which moved you back to `c91d5a0`. Both commits seem to have vanished from `git log`.

To undo the reset, you want the state **after the last good action**, which is line `{1}`:

```bash
git reset --hard HEAD@{1}     # or: git reset --hard 8d4e0b7
```

Using the hash is safer, since `{1}` will become `{2}` after the reset itself is logged.

## 4. The action types you'll see

The text between the position and the colon tells you what kind of event it was.

|Entry|What caused it|Notes|
|---|---|---|
|`commit: msg`|A normal `git commit`|The message is your commit message|
|`commit (initial): msg`|The very first commit in a repo||
|`commit (amend): msg`|`git commit --amend`|The **previous** commit is now orphaned; it's the line below|
|`commit (merge): msg`|A commit that completed a merge|Usually after resolving conflicts|
|`checkout: moving from A to B`|`git checkout` or `git switch`|`A` and `B` are branch names, or hashes if detached|
|`merge feature: Fast-forward`|A merge that just slid the branch forward|No new commit was created|
|`merge feature: Merge made by the 'ort' strategy.`|A true merge|Older Git versions say `recursive`|
|`pull: Fast-forward`|`git pull` that fast-forwarded|A `pull` is a fetch plus a merge, and it logs as one|
|`reset: moving to X`|`git reset`|`X` is exactly what you typed (`HEAD~2`, a hash, a branch)|
|`cherry-pick: msg`|`git cherry-pick`|Creates a new commit copying another|
|`revert: Revert "msg"`|`git revert`|Creates a new commit undoing another|
|`clone: from <url>`|Initial `git clone`|The oldest entry in a cloned repo|
|`rebase (start): checkout <base>`|A rebase began|`HEAD` is detached for the duration|
|`rebase (pick): msg`|One commit replayed during the rebase|One line per commit; also `squash`, `fixup`, `reword`, `edit`|
|`rebase (continue): msg`|You resolved a conflict and ran `rebase --continue`||
|`rebase (finish): returning to refs/heads/X`|Rebase completed|The branch label is moved to the final result|
|`rebase (abort): returning to ...`|You cancelled the rebase||

**Rebase deserves special attention.** A rebase appears as a _block_ of lines: a `start`, one `pick` per commit, and a `finish`. This is the evidence that a rebase **rebuilds your commits as new ones** rather than moving them. To undo a rebase, find the last line _before_ `rebase (start)` (the line below it) and reset to that hash.

## 5. The raw format behind the pretty output

`git reflog` prints a summary. The real data lives in `.git/logs/HEAD`, one line per event:

```
<old-hash> <new-hash> Your Name <you@example.com> 1727000000 +0200	reset: moving to HEAD~2
```

So each entry actually stores **both** the old and new hash, plus who, when, and why. The pretty output shows only the _new_ hash. That's the reason for the "hash is the state after" rule, and why the older hash is always the line below.

You can see the richer view without opening files:

```bash
git reflog --date=iso          # adds timestamps
git reflog --date=relative     # "3 hours ago" style
git log -g --stat              # reflog order, with changed files per entry
git reflog --no-abbrev         # full 40-character hashes
git reflog -n 10               # only the latest 10 entries
git reflog | grep rebase       # find a particular kind of event
```

## 6. Techniques for reading it effectively

**Find the "last known good" line.** Scan upward from the bottom for the last entry where things were still right (before the bad reset, merge, or rebase). Its hash is your recovery target.

**Check before you restore.** Never reset blindly. Inspect first:

```bash
git show 8d4e0b7               # what is this commit?
git diff HEAD 8d4e0b7          # how does it differ from where I am?
git branch rescue 8d4e0b7      # safest: just label it, change nothing else
```

**Spot detached-HEAD work.** A line like `checkout: moving from 4f2a9b1 to main` has a **hash on the "from" side**. That means you were detached, and any commits made in between have no branch. Find the last `commit:` before it and run `git branch rescue <hash>`.

**Same hash on adjacent lines is normal.** It means the action moved a label or changed context without changing the commit (a `checkout`, or a `pull` that did nothing).

## 7. Gotchas and edge cases

- **Numbers shift.** `HEAD@{3}` means something different after every new action. Use hashes in destructive commands.
- **`HEAD` reflog vs branch reflog.** Plain `git reflog` shows `HEAD`'s. `git reflog show main` shows only what happened to `main`, with different content: you'd see `branch: Created from HEAD`, `update by push`, and similar entries for it. Remote-tracking branches log fetches (`fetch origin: fast-forward`).
- **Abbreviated hashes can collide** in huge repos, which is rare but possible. `--no-abbrev` removes the ambiguity.
- **Timestamps are local.** They record when _you_ did it on _this machine_, not when a commit was authored.
- **Not everything is logged.** `git add`, `git status`, and edits to files don't appear, because they don't move `HEAD`. Uncommitted work wiped by `reset --hard` has no entry to recover it from.
- **Entries expire:** 90 days for reachable commits, 30 for unreachable by default. After that, `git gc` can permanently delete orphaned commits.
- **It's local only.** Nothing here is pushed, and a fresh clone starts with a nearly empty reflog.

## 8. Quick reference

|Question|Where to look|
|---|---|
|What was I at _before_ this action?|The line **below** it|
|What did a command _do_?|The text after `HEAD@{n}:`|
|Did something move `HEAD` without a commit?|`checkout`, `reset`, `merge`, `pull`, `rebase` lines|
|Where do I restore to undo a mistake?|The last good line's **hash**|





[[Git & Github]]