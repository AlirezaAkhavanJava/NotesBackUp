

## 1. What a Branch Actually Is (Recap)

A branch is a **movable pointer to a commit** — a single 41-byte file at `.git/refs/heads/<name>` containing a SHA-1 hash. Creating one is instant because it's just writing a new pointer, not copying files.

---

## 2. Creating & Switching Branches

|Command|What it does|
|---|---|
|`git branch`|List local branches (current one marked with `*`)|
|`git branch <name>`|Create a new branch (doesn't switch to it)|
|`git branch <name> <commit>`|Create a branch starting at a specific commit, not HEAD|
|`git switch <name>`|Switch to an existing branch (modern, recommended)|
|`git switch -c <name>`|Create **and** switch in one step|
|`git switch -c <name> <commit>`|Create + switch, starting from a specific commit|
|`git checkout <name>`|Older way to switch branches (still works, does more things — can be ambiguous)|
|`git checkout -b <name>`|Older equivalent of `switch -c`|
|`git switch -`|Switch back to the previously checked-out branch|

> **Why `switch` over `checkout`:** `checkout` is overloaded — it switches branches AND restores files AND does detached HEAD, all with the same command. `switch` (and `restore`) were introduced to split those responsibilities and reduce mistakes. Use `switch` for branches, `restore` for files.

---

## 3. Renaming & Deleting Branches

|Command|What it does|
|---|---|
|`git branch -m <new-name>`|Rename the **current** branch|
|`git branch -m <old> <new>`|Rename a specific branch|
|`git branch -d <name>`|Delete a branch — **safe**, refuses if unmerged|
|`git branch -D <name>`|Force delete — even if unmerged (data loss risk)|
|`git push origin --delete <name>`|Delete the branch on the remote too|

---

## 4. Listing & Inspecting Branches

|Command|What it does|
|---|---|
|`git branch`|Local branches only|
|`git branch -r`|Remote-tracking branches only|
|`git branch -a`|All branches (local + remote-tracking)|
|`git branch -v`|Local branches + last commit on each|
|`git branch -vv`|Local branches + upstream tracking + ahead/behind counts|
|`git branch --merged`|Branches already merged into current branch (safe to delete)|
|`git branch --no-merged`|Branches **not yet** merged (would lose work if deleted)|
|`git branch --contains <commit>`|Which branches contain a specific commit|
|`git log --graph --oneline --all`|Visualize all branches and how they diverge/merge|

---

## 5. Merging Branches

|Command|What it does|
|---|---|
|`git merge <branch>`|Merge the named branch into your **current** branch|
|`git merge --no-ff <branch>`|Force a merge commit even if fast-forward is possible (keeps branch history visible)|
|`git merge --ff-only <branch>`|Only merge if it can fast-forward, error otherwise|
|`git merge --squash <branch>`|Combine all commits from the branch into one set of staged changes (you commit manually after)|
|`git merge --abort`|Cancel an in-progress merge with conflicts, return to pre-merge state|
|`git merge --continue`|Continue after resolving conflicts and staging them|

### Fast-Forward vs. No-Fast-Forward Merge

```
Fast-forward (no --no-ff):
main:    A---B
feature:      \--C---D
After merge:
main:    A---B---C---D        (main just "catches up," no merge commit)

No fast-forward (--no-ff):
main:    A---B-----------M    (M = merge commit, explicit record that a branch existed)
feature:      \--C---D--/
```

**Convention:** many teams use `--no-ff` for feature branches specifically so the merge history clearly shows "a feature branch existed and was merged," rather than looking like linear work on `main`.

---

## 6. Rebasing Instead of Merging

|Command|What it does|
|---|---|
|`git rebase <branch>`|Replay your current branch's commits on top of `<branch>` — linear history, no merge commit|
|`git rebase -i <commit>`|Interactive rebase — squash, reorder, edit, drop commits|
|`git rebase --continue`|Continue after resolving a conflict mid-rebase|
|`git rebase --abort`|Cancel the rebase, return to original state|
|`git rebase --skip`|Skip the current conflicting commit entirely|
|`git rebase origin/main`|Common pattern: replay local commits on top of latest remote main|

**Merge vs Rebase — quick reminder:**

||Merge|Rebase|
|---|---|---|
|Creates new commit?|Yes (merge commit)|No — rewrites existing commits with new hashes|
|History shape|Shows branching/joining|Linear, as if work happened sequentially|
|Safe on shared branches?|Yes|No — rewrites history, dangerous if others pulled those commits|

---

## 7. Common Branching Workflows

### Feature Branch Workflow (most common)

```bash
git switch -c feature-login          # create + switch
# ... work, commit ...
git switch main
git pull                              # make sure main is current
git switch feature-login
git rebase main                       # (optional) replay onto latest main first
git switch main
git merge --no-ff feature-login       # merge feature in, keeping visible history
git push
git branch -d feature-login           # cleanup
git push origin --delete feature-login
```

### Quick Hotfix Off Main

```bash
git switch main
git switch -c hotfix-crash
# fix, commit
git switch main
git merge hotfix-crash
git push
git branch -d hotfix-crash
```

---

## 8. Branch Naming Conventions (Common Practice)

|Prefix|Use|
|---|---|
|`feature/xyz`|New feature work|
|`fix/xyz` or `bugfix/xyz`|Bug fixes|
|`hotfix/xyz`|Urgent production fix|
|`release/x.y.z`|Preparing a release|
|`chore/xyz`|Maintenance, no feature/bug (e.g. dependency bump)|
|`docs/xyz`|Documentation-only changes|

Example: `feature/user-authentication`, `fix/token-expiry-crash`

---

## 9. Syncing a Branch with Remote Changes

|Command|What it does|
|---|---|
|`git fetch && git merge origin/<branch>`|Bring remote changes into your branch (merge)|
|`git fetch && git rebase origin/<branch>`|Bring remote changes in via rebase instead|
|`git pull`|Shorthand for fetch + merge (or rebase, per config)|

---

## 10. Cleaning Up Stale Branches

|Command|What it does|
|---|---|
|`git branch --merged main`|List branches already merged into `main` — safe to delete|
|`git branch --merged main \| grep -v "main" \| xargs git branch -d`|Delete all merged branches at once (careful — review list first)|
|`git remote prune origin`|Remove local references to remote branches that were deleted on the server|
|`git fetch --prune`|Fetch + prune stale remote-tracking branches in one step|

---

## 11. Comparing Branches

|Command|What it does|
|---|---|
|`git diff main..feature-login`|Full diff between two branches|
|`git log main..feature-login --oneline`|Commits on `feature-login` not yet on `main`|
|`git log feature-login..main --oneline`|Commits on `main` not yet on `feature-login`|
|`git log --graph --oneline --all --decorate`|Visual tree of all branches and their commits|

---

## 12. Detached HEAD (When Working "Outside" a Branch)

```bash
git checkout <commit-hash>     # or git checkout <tag>
```

Puts you in **detached HEAD** — you're on a specific commit, not a branch. Any commits made here aren't attached to a branch and can be lost once you switch away, unless you save them:

```bash
git switch -c rescue-branch    # turns your detached work into a real, safe branch
```

---

**One-line summary to remember:**

> Branches are cheap, disposable, and meant to be created constantly — the real skill isn't creating them, it's managing the lifecycle: create → work → sync with main (merge/rebase) → merge back → delete. Clean branch hygiene (`--merged`, `--prune`) keeps a repo from turning into a graveyard of stale branches.




[[0 - Git 🍋‍🟩]]