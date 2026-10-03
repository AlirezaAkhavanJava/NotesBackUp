

## 1. Core intuition

Imagine two editors each take a **photocopy of the same original document** and work on it separately. You now have the original, Editor A's version, and Editor B's version. How do you combine them?

You don't compare A against B directly. That tells you the two differ, but not _who_ changed what. Instead, you compare **each version against the original**:

- A paragraph only A changed → keep A's change.
- A paragraph only B changed → keep B's change.
- A paragraph both changed in the same way → keep it.
- A paragraph both changed _differently_ → **conflict**, and a human has to decide.

That is the entire idea behind a Git merge. The "original" is the **merge base**: the most recent commit that both branches share in their history. Because Git uses three versions (base, yours, theirs), this is called a **three-way merge**.

## 2. The mental model: a merge joins two lines of history

Commits form a graph. A merge **creates a commit with two parents**, tying two lines of development back together:

```
      A---B---C        feature
     /         \
D---E---F---G---M      main   (M = merge commit, parents: G and C)
```

- `E` is the **merge base** (where the lines diverged).
- `M` is the merge commit. Its **first parent** (`G`) is the branch you were on. Its **second parent** (`C`) is the branch you merged in.
- Nothing is rewritten. `A`, `B`, `C`, `F`, `G` keep their identities. A merge only _adds_ a commit, which is why it is the safe, non-destructive way to combine work.

## 3. The two kinds of merge

### Fast-forward (no new commit)

If your branch has made no commits since the other branch diverged, there is nothing to combine. Git just slides your branch label forward:

```
Before:                      After `git switch main && git merge feature`:
D---E   main                 D---E---A---B   main, feature
     \
      A---B  feature
```

No merge commit, no history of "a branch existed." It works only when the current branch is an **ancestor** of the one you're merging.

### True (three-way) merge

When both branches have new commits, Git finds the merge base, computes both sides' changes, combines them, and creates a **merge commit**.

### Controlling it

|Command|Behavior|
|---|---|
|`git merge feature`|Fast-forward if possible, otherwise a merge commit|
|`git merge --no-ff feature`|**Always** create a merge commit, even if a fast-forward was possible. Preserves the fact that a feature branch existed|
|`git merge --ff-only feature`|Fast-forward or **fail**. Never creates a merge commit|

## 4. The mechanics, step by step

Running `git merge feature` while on `main`:

1. **Find the merge base:** `git merge-base main feature`.
2. **Compute two diffs:** base → `main` and base → `feature`.
3. **Combine them hunk by hunk**, using the rules from section 1.
4. **Write the result** into your working tree and the index (the staging area).
5. **If no conflicts:** Git creates the merge commit automatically (opening an editor for the message, unless you pass `--no-edit`).
6. **If conflicts:** Git stops halfway, leaves the conflicting files marked, and waits for you.

Useful inspection commands, before you merge:

```bash
git merge-base main feature       # what's the common ancestor?
git log main..feature --oneline   # commits that feature has and main lacks
git diff main...feature           # three dots: changes on feature since the merge base
git diff main..feature            # two dots: plain difference between the two tips
```

The three-dot form is the one that mirrors what a merge actually brings in. The two-dot form also shows changes that happened on `main`, in reverse, which is usually not what you want.

## 5. Conflicts

A conflict is not an error. It's Git saying: "both sides changed this same spot differently, and I won't guess."

### What you see

```java
<<<<<<< HEAD
    private int maxRetries = 3;
=======
    private int maxRetries = 5;
>>>>>>> feature
```

- Between `<<<<<<<` and `=======`: **your side** (the branch you're on).
- Between `=======` and `>>>>>>>`: **their side** (the branch being merged in).

For more context, switch to diff3 style, which also shows the base:

```bash
git config --global merge.conflictStyle zdiff3   # or diff3 on older Git
```

```java
<<<<<<< HEAD
    private int maxRetries = 3;
||||||| base
    private int maxRetries = 2;
=======
    private int maxRetries = 5;
>>>>>>> feature
```

Seeing the original value makes it far clearer what each side intended. This is the single most useful setting for resolving conflicts.

### Resolving

```bash
git status                     # lists "both modified" files
# edit each file: pick/combine, delete the marker lines
git add path/to/File.java      # staging marks it as resolved
git merge --continue           # or: git commit
```

To bail out completely and return to the pre-merge state:

```bash
git merge --abort
```

### Under the hood: the three stages

During a conflict the index holds **three versions** of each conflicted file:

|Stage|Contents|
|---|---|
|1|Base (common ancestor)|
|2|"Ours" (current branch)|
|3|"Theirs" (branch being merged in)|

```bash
git ls-files -u                       # list unmerged entries with stage numbers
git show :1:File.java                 # base version
git show :2:File.java                 # ours
git show :3:File.java                 # theirs
git checkout --ours File.java         # take our whole file
git checkout --theirs File.java       # take their whole file
```

Gotcha: **"ours" and "theirs" swap meaning during a rebase** (ours is the branch being rebased onto, theirs is your commits being replayed). In a merge, "ours" is where you are. This catches almost everyone once.

Other helpers: `git diff --name-only --diff-filter=U` lists unresolved files, `git log --merge -p File.java` shows the commits from both sides touching the conflict, and `git mergetool` opens a visual three-pane tool.

## 6. Strategies and options

Git has _strategies_ (`-s`) and _strategy options_ (`-X`). Mixing them up causes real mistakes.

- **`ort`** is the default strategy (since Git 2.34; it replaced `recursive`). It handles renames, and it deals with multiple merge bases (the "criss-cross" case) by first merging those bases together.
- **`-X ours` / `-X theirs`** applies only to **conflicting hunks**: for those spots, prefer one side. Non-conflicting changes from both sides are still combined normally.
- **`-s ours`** is completely different: it records a merge commit but **discards everything from the other branch**. The result is your tree unchanged, with history saying the other branch was merged. It's occasionally used to retire an old branch without taking its changes.

Quick comparison:

||Takes other side's non-conflicting changes?|Resolves conflicts how?|
|---|---|---|
|`-X ours`|Yes|Prefers our side|
|`-X theirs`|Yes|Prefers their side|
|`-s ours`|**No**, discards them all|N/A|

`-X theirs` can silently throw away work in conflicts, so use it deliberately, not as a shortcut to make the red markers disappear.

## 7. Variants worth knowing

**Squash merge**

```bash
git merge --squash feature
git commit
```

Applies all of the branch's changes to your working tree as one set, **without a merge commit and without recording a second parent**. History stays linear, but Git no longer knows `feature` was merged, so `git branch -d feature` refuses (use `-D`), and merging `feature` again later would try to reapply the same changes. Good for tidying many small WIP commits; bad if you plan to keep working on that branch.

**Merge without committing**

```bash
git merge --no-commit --no-ff feature
```

Stops after merging so you can inspect, run the tests, or tweak before committing. This is worth doing for risky merges because of the next gotcha.

**Octopus merge**

```bash
git merge a b c
```

Merges more than two branches into one commit with multiple parents. It refuses if any conflict arises, so it's for clean, simple combinations.

## 8. Nuances and gotchas

- **Semantic conflicts.** A merge can succeed _textually_ and still be broken. If A renames a method and B adds a new call to the old name, no lines overlap, so Git reports no conflict, but the code won't compile. Always build and run tests after merging, even a clean one. This is a real concern in Java projects with many callers of a changed signature.
- **Uncommitted changes.** Git refuses to merge if your uncommitted edits touch files the merge would change. Commit or `git stash` first.
- **Rename detection is heuristic.** Git doesn't track renames explicitly; it infers them from similarity (roughly 50%+ identical content). A file that is renamed _and_ heavily rewritten may show up as delete + add, producing confusing conflicts.
- **Whitespace and line endings** create phantom conflicts. Mixed CRLF/LF files are a classic cause; a `.gitattributes` file or `core.autocrlf` settings help.
- **Binary files** can't be merged line by line; you must choose one side (`--ours` or `--theirs`).
- **Merge commits and history reading.** `git log --first-parent` follows only the main line (what happened _to `main`_, one entry per merged feature), while plain `git log` interleaves everything. `HEAD^1` is the first parent and `HEAD^2` the second.
- **Re-merging after resolving.** Git remembers that a merge happened (via the second parent), so a later merge of the same branch only brings in _new_ commits. Enabling `git config rerere.enabled true` also makes Git remember how you resolved a conflict and replay that resolution if the same conflict recurs.

## 9. Undoing a merge

- **Mid-merge, with conflicts:** `git merge --abort`.
- **Merged locally, not yet pushed:** `git reset --hard ORIG_HEAD` (Git sets `ORIG_HEAD` right before a merge). This discards the merge, so don't use it with other uncommitted work.
- **Already pushed/shared:** don't rewrite history. Create a new commit that reverses it:

```bash
git revert -m 1 <merge-commit-hash>
```

`-m 1` tells Git which parent is the "mainline" to keep (parent 1, the branch you merged _into_). Gotcha: after reverting a merge, **merging that same branch again will not bring its changes back**, because Git considers them already merged (and reverted). To re-bring them, revert the revert first.

## 10. Merge vs rebase vs pull

||Merge|Rebase|
|---|---|---|
|History|Preserves true history, adds a merge commit|Rewrites your commits into a straight line|
|Existing commits|Untouched|Replaced with new copies (new hashes)|
|Safe on shared branches?|Yes|**No**, rewriting published commits breaks collaborators|
|Conflicts|Resolve once|May resolve once per replayed commit|

Rule of thumb: **merge to integrate shared work, rebase to tidy your own unpublished commits.**

`git pull` is `git fetch` followed by `git merge` (or `git rebase` if you set `pull.rebase true`). If `git pull` produces surprising merge commits, `git config --global pull.ff only` makes it refuse anything but a fast-forward, so you decide explicitly how to integrate.

On GitHub/GitLab, the pull request buttons map to these ideas: **Merge commit** (`--no-ff`), **Squash and merge** (`--squash`), and **Rebase and merge** (replay commits, linear history).

## 11. Typical workflow

```bash
git switch main
git pull                          # update first
git merge --no-commit --no-ff feature
# inspect, build, run tests
git commit                        # or: git merge --abort
```

And a mental checklist when conflicts appear:

1. `git status` to see which files conflict.
2. Open each, understand _both_ intentions (diff3 style helps), and combine.
3. `git add` each file, then `git merge --continue`.
4. Compile and test, since resolved code can still be wrong.




[[Git & Github]]