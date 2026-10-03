


# `git log --oneline -p -1 main`

## 1. Core intuition

Think of the commit history as a **stack of photo albums**, where each commit is a snapshot with a caption. This command says:

> "Starting from where `main` points, show me **just the newest entry**, with its **caption squeezed onto one line**, followed by **exactly what changed** in that commit."

It's a quick way to answer: _"What was the last thing that landed on `main`, and what did it actually change?"_

## 2. Breaking it down piece by piece

|Part|Meaning|
|---|---|
|`git log`|Walk the commit history backwards, newest first|
|`--oneline`|Compress each commit's header into one line: abbreviated hash + subject (shorthand for `--pretty=oneline --abbrev-commit`)|
|`-p`|Also show the **patch**: the diff of what this commit changed (same as `--patch` or `-u`)|
|`-1`|Limit to **1 commit** (shorthand for `-n 1` or `--max-count=1`)|
|`main`|The **starting point**: begin walking from the commit that `main` points to|

Flag order doesn't matter. `git log -1 -p --oneline main` is identical.

## 3. What the output looks like

```
8d4e0b7 Fix null check in TaskService
diff --git a/src/main/java/com/arcade/doitlater/TaskService.java b/src/main/java/com/arcade/doitlater/TaskService.java
index 3f9a1c2..b71e4d0 100644
--- a/src/main/java/com/arcade/doitlater/TaskService.java
+++ b/src/main/java/com/arcade/doitlater/TaskService.java
@@ -42,7 +42,9 @@ public class TaskService {
     public Task findById(Long id) {
-        return taskRepository.findById(id).get();
+        return taskRepository.findById(id)
+                .orElseThrow(() -> new TaskNotFoundException(id));
     }
```

Two zones:

1. **The header line:** `8d4e0b7 Fix null check in TaskService` is the hash and subject, courtesy of `--oneline`.
2. **The patch:** one block per changed file, courtesy of `-p`.

### Reading the patch

```
diff --git a/path b/path       ← which file (a = before, b = after)
index 3f9a1c2..b71e4d0 100644 ← blob hashes before..after, and file mode
--- a/path                    ← the "before" version
+++ b/path                    ← the "after" version
@@ -42,7 +42,9 @@ ...         ← hunk header
```

The hunk header `@@ -42,7 +42,9 @@` reads: "in the **old** file, this chunk starts at line 42 and spans 7 lines; in the **new** file, it starts at line 42 and spans 9." The text after the second `@@` (here, the class name) is Git's guess at the enclosing function or class, to help you orient. Inside a hunk:

- `-` red lines: removed (existed before, gone now)
- `+` green lines: added
- lines with a leading space: **context**, unchanged (3 lines above and below by default)

Those unchanged context lines are the same "anchor" idea that decides whether two edits conflict when merging.

## 4. Why it works this way

`git log` is a **history walker**. You give it a starting commit, and it follows parent links backwards. `-1` stops the walk after one commit. `main` just names the starting point; without it, the default start is `HEAD`.

The important concept: **a commit doesn't store a diff, it stores a full snapshot** (a tree). `-p` _computes_ the diff on the fly by comparing the commit's snapshot with its **parent's** snapshot. This has two consequences you'll see in the edge cases below.

## 5. Edge cases and gotchas

**1. `main` vs `HEAD` can differ.** If you're on `feature/auth`, then `git log -1 main` shows `main`'s latest commit, not yours. Plain `git log -1 -p` (no argument) shows `HEAD`, the commit you're on.

**2. Remote vs local `main`.** `main` is your _local_ branch. The server's version is `origin/main`, which updates only when you `git fetch`. To see what's new upstream:

```bash
git fetch
git log --oneline -p -1 origin/main
```

**3. If the latest commit is a merge commit, you'll see no diff.** By default `-p` shows **nothing** for merge commits, because they have two parents and it's ambiguous which one to diff against. You'll get just the one-line header. This is the most common "why is it empty?" surprise. Choose how to see it:

```bash
git log --oneline -p -1 -m main            # separate diff against EACH parent
git log --oneline -p -1 -m --first-parent main   # diff only against the first parent
                                                  # (= "what did this merge bring into main")
git log --oneline -p -1 --cc main          # combined diff: only places that differ from ALL parents
```

`-m --first-parent` is usually the answer, since parent 1 is the branch that was merged _into_. `--cc` is the one that displays conflict resolutions, which is handy for auditing a merge you resolved by hand.

**4. The very first commit** is diffed against an **empty tree**, so everything shows as `+` lines.

**5. A branch and a file with the same name.** If you have a file called `main`, Git can't tell whether you mean the branch or the path, and it errors with an "ambiguous argument" message. The `--` separator disambiguates:

```bash
git log --oneline -p -1 main --        # main is a revision
git log --oneline -p -1 -- main        # main is a file path
```

**6. Output opens in a pager** (`less`) when it's long. Press `q` to quit, `/` to search. Disable it with `git --no-pager log ...` or `git config --global core.pager cat`.

**7. Colors disappear when piping.** Use `--color=always` if you pipe to something that renders ANSI.

**8. Pure renames show as renames,** not delete+add, because `git log -p` follows the same rename detection as merging (similarity-based, roughly 50%).

**9. `-1` counts commits in the walk, not "the latest on the branch" in a strict sense.** On a history with merges, "newest" means the first one the traversal emits (by default, reverse chronological by commit date). For the newest commit _on the first-parent line_, add `--first-parent`.

## 6. Useful variations

```bash
git log --oneline -p -1                       # latest commit on the current HEAD
git log --oneline -p -3 main                  # last 3 commits with their diffs
git log --oneline --stat -1 main              # summary of files + line counts, no full diff
git log --oneline --name-status -1 main       # just which files: A(dded) M(odified) D(eleted) R(enamed)
git log -p -1 -U10 main                       # 10 lines of context instead of 3
git log -p -1 -w main                         # ignore whitespace-only changes
git log -p -1 main -- src/main/java           # only changes touching that path
git log -p --follow -- path/File.java         # a file's history across renames
git log -p -S "taskRepository" main           # commits that added/removed that exact string ("pickaxe")
git log -p -G "regex" main                    # commits whose diff matches a regex
git log -p main..feature                      # commits on feature that main lacks, with diffs
```

`-S` is particularly powerful for archaeology: "when did this line first appear, and when did it vanish?"

## 7. How this relates to similar commands

```bash
git show main
```

is nearly equivalent for a single commit: it shows the full commit header (author, date, full message) plus the patch, and **it handles merge commits** with a combined diff by default. `git show` is "show me this one object"; `git log -p` is "walk history and show patches." For one commit, `git show --oneline main` is usually the simpler tool.

|You want|Use|
|---|---|
|Latest commit's changes, compactly|`git log --oneline -p -1 main`|
|Everything about one specific commit|`git show <hash>`|
|What changed between two points|`git diff A B`|
|What a branch added since diverging|`git diff main...feature` (three dots)|
|Which commits touched a file|`git log -p -- path`|

**Connection to merging:** during a conflicted merge, `git log --merge -p -- path/File.java` uses the same machinery to show commits from **both sides** that touched the conflicted file, which is a quick way to understand _why_ it conflicts.

**Connection to the reflog:** `git log` walks **ancestry** (parent links), while `git reflog` walks **your action history**. After a reset, `git log -p -1 HEAD@{1}` can show the patch of the commit you were on _before_ the reset, a neat way to confirm what you're about to restore.

## 8. Quick mental checklist

1. No output diff? It's probably a **merge commit**; add `-m --first-parent`.
2. Seeing the wrong commit? Check **`main` vs `HEAD` vs `origin/main`**.
3. Too much noise? Swap `-p` for `--stat`, or scope with `-- path`.
4. Want the whole story of one commit? Use `git show`.




[[Git & Github]]