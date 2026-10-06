

## 1. What the staging area is

Git has three places your changes can live:

|Area|What it holds|
|---|---|
|**Working directory**|The actual files on disk, as you edit them|
|**Staging area** (the _index_)|A draft of the next commit|
|**Repository**|Committed history|

`git add` copies a file's current state from the working directory into the staging area. A commit is built **from the staging area**, not from your working directory. That is the key fact for everything below.

## 2. What a rebase does at each step

Rebase replays your commits one at a time. For each one, Git:

1. Applies that commit's changes onto the new base.
2. If it applies cleanly, makes the commit automatically.
3. If it conflicts, **stops** and hands control to you.

When it stops, the file is in a half-merged state with conflict markers, and Git has marked that path as **unmerged** in the index.

## 3. Why `git add` is required

`git rebase --continue` means "build the commit now from whatever is staged, then keep going." So it needs two things from the staging area:

**a) The content.** The commit is made from the index. If you fixed the file but didn't stage it, the index still holds the conflicted version (or nothing for that path), so your fix would not be in the commit.

**b) The "resolved" signal.** Git has no way to know you're finished editing. A file full of `<<<<<<<` markers is still valid text. Running `git add file` is how you tell Git: _"this path is resolved, I'm happy with it."_ It clears the unmerged status.

If you skip it, Git refuses:

```
file.txt: needs merge
You must edit all merge conflicts and then
mark them as resolved using git add
```

## 4. A side effect worth knowing

If you stage a file that **still contains conflict markers**, Git will happily accept it, because it only checks that you ran `add`, not that the content is sensible. The markers then get committed. Before `git add`, check:

```bash
git diff --check     # warns about leftover conflict markers
git status           # confirms which files are unmerged
```

Also, `git add .` stages everything, including unrelated edits. Staging only the resolved file is safer:

```bash
git add path/to/file
```

## 5. The sequence

1. Rebase stops: conflict in `file`.
2. You edit `file` and remove the markers (working directory).
3. `git add file` copies the fix into the index and marks it resolved.
4. `git rebase --continue` makes the commit from the index and moves on.

Same rule applies to `git merge` (you `git add`, then `git commit`) and `git cherry-pick --continue`.







[[Git & Github]]