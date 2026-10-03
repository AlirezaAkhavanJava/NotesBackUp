


## 1. Core intuition

Think of Git's index (staging area) as a **checklist of every file in the project**, where each file is normally marked "settled." When a merge can't settle a file, Git leaves it marked **"unresolved"** on that checklist. Every command below is just a different way of asking Git: _"show me the entries on the checklist still marked unresolved."_

Technically, a settled file has one index entry at **stage 0**. A conflicted file has no stage 0 entry. Instead it has up to three: stage 1 (base), stage 2 (ours), stage 3 (theirs). "Conflicted" and "has stages 1-3" mean the same thing.

## 2. The main ways to see them

### a) `git status`: the friendly view

```bash
git status
```

```
On branch feature/audit
You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Changes to be committed:
        modified:   src/main/java/com/arcade/doitlater/TaskController.java

Unmerged paths:
  (use "git add <file>..." to mark resolution)
        both modified:   src/main/java/com/arcade/doitlater/TaskService.java
        deleted by them: src/main/resources/old-config.yml
```

The key is the **"Unmerged paths"** section. Files under "Changes to be committed" merged cleanly and are already staged. Only the unmerged ones need your attention.

### b) `git diff --name-only --diff-filter=U`: just the filenames

```bash
git diff --name-only --diff-filter=U
```

```
src/main/java/com/arcade/doitlater/TaskService.java
src/main/resources/old-config.yml
```

`U` means "unmerged." This is the cleanest output for scripts, for piping into other commands, and for a quick count:

```bash
git diff --name-only --diff-filter=U | wc -l
```

### c) `git status -s`: compact, with a code per file

```bash
git status -s
```

```
M  src/main/java/com/arcade/doitlater/TaskController.java
UU src/main/java/com/arcade/doitlater/TaskService.java
UD src/main/resources/old-config.yml
```

Conflicted files are the ones whose two-letter code includes a `U` (or is `AA` or `DD`). The two columns describe **our side** and **their side**:

|Code|Meaning|
|---|---|
|`UU`|Both modified|
|`AA`|Both added (same path, different content)|
|`DD`|Both deleted (rename conflicts can cause this)|
|`AU`|Added by us|
|`UA`|Added by them|
|`DU`|Deleted by us, modified by them|
|`UD`|Deleted by them, modified by us|

Anything else (`M` , `A` , and so on) merged cleanly.

### d) `git ls-files -u`: the raw checklist

```bash
git ls-files -u
```

```
100644 3f9a1c2d... 1	src/.../TaskService.java
100644 b71e4d0a... 2	src/.../TaskService.java
100644 9c8d7e61... 3	src/.../TaskService.java
```

The number before the tab is the **stage**: 1 is base, 2 is ours, 3 is theirs. A file listed with all three is a classic content conflict. A file with only stages 1 and 2 means "they deleted it, we modified it" (and 1 and 3 means the reverse). Names only, without duplicates:

```bash
git ls-files -u | cut -f2 | sort -u
```

This is the most direct view of what Git itself tracks, which is why the other commands agree with it.

### e) The merge output itself

When you ran the merge, Git printed the list immediately:

```
Auto-merging src/main/java/com/arcade/doitlater/TaskService.java
CONFLICT (content): Merge conflict in src/main/java/com/arcade/doitlater/TaskService.java
CONFLICT (modify/delete): old-config.yml deleted in main and modified in HEAD.
Automatic merge failed; fix conflicts and then commit the result.
```

The text in parentheses tells you the **type** of conflict, which tells you how to resolve it. If this scrolled off screen, `git status` shows the same information again.

## 3. Finding the conflict _inside_ a file

Knowing the file is half the job. Locate the markers:

```bash
git diff --check
```

```
src/.../TaskService.java:14: leftover conflict marker
src/.../TaskService.java:18: leftover conflict marker
src/.../TaskService.java:22: leftover conflict marker
```

This gives file and line number for each marker line. It's also your **final safety check**: Git does _not_ verify that markers are gone when you `git add` a file, so a leftover `<<<<<<<` can get committed. Run `git diff --check` before `git merge --continue`.

Alternatively, with grep:

```bash
git grep -n '^<<<<<<< '        # tracked files; anchored to avoid false hits
grep -rn '^<<<<<<< ' src/      # plain grep, works on untracked files too
```

Search for `^<<<<<<<` (with the trailing space) rather than `=======`, because `=======` also appears legitimately in Markdown headings and comment banners.

To see the conflict as Git sees it, plain `git diff` during a merge shows a **combined diff** with two columns instead of one, so you can see what each side contributed.

## 4. Seeing _why_ a file conflicts

```bash
git log --merge -p -- path/to/TaskService.java
```

`--merge` limits the log to commits from **both sides** that touch the conflicted file, with their patches. It lets you read each author's intent before deciding. To see the three versions directly:

```bash
git show :1:path/TaskService.java    # base
git show :2:path/TaskService.java    # ours
git show :3:path/TaskService.java    # theirs
```

## 5. Edge cases and gotchas

- **A resolved file disappears from the list.** Once you `git add` a file, its stages collapse back to stage 0 and it's no longer "unmerged," even if you left markers in it. That's why `git diff --check` matters, and why you shouldn't `git add .` blindly during a merge.
- **Binary files have no markers.** A conflicted image or `.jar` shows up in the lists above, but you won't find `<<<<<<<` in it. Choose a side with `git checkout --ours -- file` or `--theirs`.
- **Modify/delete and rename conflicts** look odd in `git status` (`deleted by them`, `added by us`). The file may exist in your working tree with _no markers at all_, because there's nothing to mark; you must decide whether to keep it (`git add file`) or delete it (`git rm file`).
- **Other operations conflict too.** All of these commands work the same way during `git rebase`, `git cherry-pick`, `git revert`, and a conflicted `git stash pop`. Only the status header differs (`rebase in progress`, and so on). Remember that "ours" and "theirs" flip in a rebase.
- **Clean merge, broken code.** An empty "unmerged" list doesn't mean the merge is correct. Git can't see semantic conflicts, such as two Flyway migrations with the same version number. Compile and run the tests.
- **`git status` shows a lot of noise in big merges.** The `--diff-filter=U` form cuts straight to what matters.

## 6. In IntelliJ IDEA (since you work in Java/Spring)

- Conflicted files show up in **red** in the Project tree and in the **Commit / Git** tool window, under "Merge Conflicts".
- **Git → Resolve Conflicts…** (or the _Merge…_ button) opens a list of conflicted files.
- Selecting a file opens a **three-pane merge tool**: ours on the left, theirs on the right, and the result in the middle, with buttons to accept either side for each hunk.

Under the hood it's reading the same stage-1/2/3 entries from the index, so the terminal and IDE always agree.

## 7. Quick reference

|You want|Command|
|---|---|
|Full picture, human-friendly|`git status`|
|Just the filenames|`git diff --name-only --diff-filter=U`|
|Compact list with conflict type codes|`git status -s`|
|The raw index stages|`git ls-files -u`|
|Line numbers of markers|`git diff --check`|
|Why it conflicts|`git log --merge -p -- file`|
|Base / ours / theirs contents|`git show :1:file` / `:2:` / `:3:`|




[[Git & Github]]