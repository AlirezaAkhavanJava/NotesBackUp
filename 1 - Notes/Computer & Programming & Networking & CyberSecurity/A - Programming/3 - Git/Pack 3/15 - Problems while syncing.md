
---

## 1. Merge Conflicts

### What Causes It

The same lines of a file were changed differently in two branches/commits being combined, and Git can't automatically decide which version is correct.

### What It Looks Like

```bash
git merge feature-x
```

```
Auto-merging App.java
CONFLICT (content): Merge conflict in App.java
Automatic merge failed; fix conflicts and then commit the result.
```

### Inside the File

```java
<<<<<<< HEAD
System.out.println("Hello from main");
=======
System.out.println("Hello from feature-x");
>>>>>>> feature-x
```

- Everything between `<<<<<<< HEAD` and `=======` = your current branch's version
- Everything between `=======` and `>>>>>>> feature-x` = the incoming branch's version

### How to Solve

```bash
git status                    # see which files are conflicted
# manually edit the file — delete markers, keep the correct code (or combine both)
git add <file>                 # mark as resolved
git commit                     # completes the merge
```

To bail out entirely:

```bash
git merge --abort              # cancel, return to pre-merge state
```

Use a visual merge tool if preferred:

```bash
git mergetool
```

---

## 2. Rebase Conflicts

### What Causes It

Same idea as a merge conflict, but happens **per-commit** while replaying your commits one at a time onto a new base.

```bash
git rebase main
```

```
CONFLICT (content): Merge conflict in App.java
error: could not apply a1b2c3d... your commit message
```

### How to Solve

```bash
# edit file, resolve markers
git add <file>
git rebase --continue           # move to next commit, repeat if more conflicts appear
```

To escape:

```bash
git rebase --abort              # cancel entirely, return to pre-rebase state
git rebase --skip                # skip this one commit (rare — use carefully, may lose that commit's change)
```

**Key difference from merge:** conflicts can happen multiple times, once per replayed commit — resolve each one, `continue`, repeat.

---

## 3. Push Rejected — Non-Fast-Forward

_(You already hit this one with `webflyx`.)_

```
! [rejected]  main -> main (non-fast-forward)
error: failed to push some refs
```

### Cause

Local branch is behind or diverged from remote.

### Solve

```bash
git pull                        # if remote has legitimate new commits you need
git push
# — or, if YOU intentionally rewrote history (amend/rebase) —
git push --force-with-lease
```

---

## 4. "Branch has diverged"

```
Your branch and 'origin/main' have diverged,
and have 1 and 1 different commits each, respectively.
```

### Cause

Both local and remote have unique commits since the last common point.

### Solve

```bash
git log main..origin/main --oneline   # see what's different first
git pull                              # merge or rebase, per your config
# or, if divergence was from your own history rewrite:
git push --force-with-lease
```

---

## 5. `fatal: refusing to merge unrelated histories`

### Cause

You're trying to merge/pull two repos/branches that don't share a common commit ancestor — often happens when a repo was re-initialized, or you're combining two separately-created repos.

### Solve

```bash
git pull origin main --allow-unrelated-histories
```

_(Use deliberately — this can create a messy merge if the two histories are truly unrelated projects.)_

---

## 6. Detached HEAD

```bash
git checkout a1b2c3d
```

```
You are in 'detached HEAD' state...
```

### Cause

You checked out a specific commit or tag instead of a branch — you're not "on" any branch anymore.

### Risk

Any new commits made here can be **lost** (orphaned) once you switch to a branch, unless saved.

### Solve

```bash
git switch -c rescue-branch      # turn current state into a real branch — saves your work
# or, if you don't need to keep changes:
git switch main                    # just leave detached HEAD, nothing lost (nothing was changed)
```

---

## 7. Accidentally Committed to the Wrong Branch

### Cause

Forgot to switch branches before committing.

### Solve

```bash
git log --oneline -1              # note the commit hash
git reset --soft HEAD~1            # undo the commit, keep changes staged
git switch correct-branch
git commit -m "message"            # commit it properly here instead
```

---

## 8. Uncommitted Changes Blocking an Operation

```
error: Your local changes to the following files would be overwritten by checkout/merge/rebase
```

### Cause

Git won't let an operation silently destroy uncommitted work.

### Solve — three options

```bash
git stash                          # temporarily shelve changes
git switch other-branch            # (or pull/rebase now works)
git stash pop                       # bring changes back later

# or
git commit -am "wip"                 # just commit them (can clean up later)

# or, if you don't need the changes at all:
git restore <file>                    # discard changes to a specific file
git reset --hard                       # discard ALL uncommitted changes (careful!)
```

---

## 9. Accidentally Deleted a Branch / Lost Commits

### Cause

`git branch -D`, a bad `reset --hard`, or a botched rebase.

### Solve — the safety net

```bash
git reflog                          # shows every place HEAD has pointed, including "lost" commits
git checkout <hash-from-reflog>      # go look at it
git switch -c recovered-branch       # turn it back into a real branch
```

**Reflog is your undo button for almost everything** — commits aren't actually gone until Git's garbage collector runs (which is infrequent and conservative).

---

## 10. Wrong Commit Message / Forgot to Add a File

### Not yet pushed:

```bash
git add forgotten-file.java
git commit --amend --no-edit          # add to last commit, keep message
git commit --amend -m "new message"    # or fix the message too
```

### Already pushed (only if you're sure nobody pulled it yet):

```bash
git commit --amend
git push --force-with-lease
```

---

## 11. Merged the Wrong Branch

### If not pushed yet:

```bash
git reset --hard HEAD~1               # undo the merge commit entirely (if it was the last action)
```

### If already pushed (safe undo, doesn't rewrite history):

```bash
git revert -m 1 <merge-commit-hash>    # creates a NEW commit that undoes the merge
```

`-m 1` tells Git which parent (mainline) to revert to — required specifically for merge commits.

---

## 12. `fatal: not a git repository`

### Cause

You're running a git command outside any `.git`-tracked folder.

### Solve

```bash
cd /path/to/your/repo         # navigate into the actual repo
git init                        # or, if it should be a new repo, create one
```

---

## 13. `error: src refspec main does not match any`

### Cause

You tried to push a branch that doesn't exist yet locally (often: no commits made yet, or wrong branch name/typo).

### Solve

```bash
git branch                      # confirm actual branch name
git log                          # confirm you have at least one commit
git commit -m "initial commit"    # if nothing committed yet
git push -u origin main
```

---

## 14. `Permission denied (publickey)`

### Cause

SSH remote URL, but your SSH key isn't set up or added to GitHub.

### Solve

```bash
ssh -T git@github.com            # test connection
ssh-keygen -t ed25519 -C "your_email"   # generate a key if needed
cat ~/.ssh/id_ed25519.pub         # copy this to GitHub → Settings → SSH Keys
```

Or switch to HTTPS instead:

```bash
git remote set-url origin https://github.com/AlirezaAkhavanJava/webflyx.git
```

---

## 15. Large File Rejected by GitHub

```
remote: error: File big-video.mp4 is 150.00 MB; this exceeds GitHub's file size limit of 100.00 MB
```

### Solve

```bash
git rm --cached big-video.mp4      # remove from tracking (keep file locally)
echo "big-video.mp4" >> .gitignore
git commit -m "remove large file"
# for legitimately needed large files:
git lfs install
git lfs track "*.mp4"
git add .gitattributes big-video.mp4
git commit -m "track large file with LFS"
```

_(If it's already baked into history and blocking every push, it needs removing from history entirely — `git filter-repo` or BFG Repo-Cleaner, a more advanced topic.)_

---

## 16. Case-Sensitivity Conflicts (Common on Debian, since Linux filesystems ARE case-sensitive)

```
error: the following untracked working tree files would be overwritten
```

Or files appear duplicated (`File.java` and `file.java`) after pulling from a contributor on Windows/macOS (case-insensitive filesystems).

### Solve

```bash
git mv File.java temp.java
git mv temp.java file.java
git commit -m "fix filename casing"
```

---

## Master Recovery Command — When All Else Fails

```bash
git reflog                          # find the last known-good state
git reset --hard <hash>              # forcibly return to it
```

**This works for almost any local disaster** — bad merge, bad rebase, accidental hard reset, deleted branch — as long as the commit was made at some point (even briefly), reflog remembers it, typically for 90 days by default.

---

## Quick Reference Table

|Error / Conflict|Fastest Fix|
|---|---|
|Merge conflict|Edit markers → `add` → `commit`|
|Rebase conflict|Edit markers → `add` → `rebase --continue`|
|Push rejected (non-ff)|`pull` then `push`, or `push --force-with-lease`|
|Branch diverged|`pull` (merge/rebase), or force-push if intentional|
|Unrelated histories|`pull --allow-unrelated-histories`|
|Detached HEAD|`switch -c new-branch` to save work|
|Uncommitted changes blocking|`stash`, do the operation, `stash pop`|
|Lost commits/branch|`reflog` → `reset --hard` or `switch -c`|
|Wrong commit message|`commit --amend`|
|Wrong merge|`revert -m 1 <hash>` (if pushed) or `reset --hard` (if not)|
|Not a git repo|`cd` into repo or `git init`|
|SSH permission denied|Set up SSH key or switch to HTTPS|
|File too large|`.gitignore` + `rm --cached`, or Git LFS|

---

**One-line summary to remember:**

> Almost every Git "disaster" is recoverable because Git rarely deletes anything immediately — `reflog` is the universal safety net, conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) are just decision points requiring a human choice, and `--abort` exists on every operation (`merge`, `rebase`, `cherry-pick`) as an escape hatch.




[[0 - Git 🍋‍🟩]]