

## 1. What is a merge?

**Merge** is the Git operation that combines the histories of two branches.

Suppose you have:

```text
A---B---C        main
     \
      D---E      feature
```

You are on `main` and want to integrate `feature`:

```bash
git merge feature
```

Git combines the two histories:

```text
A---B---C-------M    main
     \         /
      D---E---       feature
```

`M` is a **merge commit**.

### Definition

> **A merge combines the changes and commit histories of another branch into the currently checked-out branch.**

The branch you are **on** is the branch that receives the merge.

For example:

```bash
git switch main
git merge feature
```

means:

> Take `feature` and merge it **into `main`**.

It does **not** mean the opposite.

---

# 2. The most important merge rule

Remember this:

```bash
git merge <branch>
```

means:

```text
CURRENT BRANCH ← <branch>
```

Example:

```bash
git switch main
git merge feature
```

```text
feature ────────┐
                ↓
main ←──────── MERGE
```

So:

```bash
git switch feature
git merge main
```

is a completely different operation.

---

# 3. Before merging

You should understand the repository's graph first.

Useful:

```bash
git status
```

```bash
git log --oneline --graph --decorate --all
```

Example:

```text
* 7c91abc (feature) Add authentication
* 4a21d32 Add login page
| * 81bd123 (main) Update README
|/
* 1234567 Initial commit
```

This tells you that `feature` and `main` have diverged.

---

# 4. Basic merge commands

|Command|Meaning|
|---|---|
|`git merge <branch>`|Merge branch into current branch|
|`git merge --no-ff <branch>`|Always create a merge commit|
|`git merge --ff-only <branch>`|Merge only if fast-forward is possible|
|`git merge --abort`|Cancel an in-progress merge|
|`git merge --continue`|Continue after resolving conflicts|
|`git merge --quit`|Stop merge operation but leave working-tree/index state|
|`git merge --squash <branch>`|Combine changes without creating a merge commit|
|`git merge --no-commit <branch>`|Perform merge but stop before creating merge commit|
|`git merge --edit <branch>`|Open editor for merge commit message|
|`git merge --no-edit <branch>`|Accept generated merge message|
|`git merge --stat <branch>`|Show merge statistics|
|`git merge --verbose <branch>`|Show more information|
|`git merge --abort`|Restore state from before merge|

---

# 5. Fast-forward merge

This is the simplest kind of merge.

Suppose:

```text
A---B---C    main
         \
          D---E    feature
```

Actually, if `feature` was created from `C` and `main` hasn't moved:

```text
A---B---C    main
         \
          D---E  feature
```

When you do:

```bash
git switch main
git merge feature
```

Git can simply move `main` forward:

```text
A---B---C---D---E    main
                 ↑
              feature
```

No merge commit is necessary.

This is called a:

> **Fast-forward merge**

Git essentially moves the branch pointer.

---

# 6. `--no-ff`

You can force Git to create a merge commit:

```bash
git merge --no-ff feature
```

Instead of:

```text
A---B---C---D---E
```

you get:

```text
A---B---C-------M
         \     /
          D---E
```

Why?

Because the merge commit records:

> "This entire line of development was merged into this branch."

This can make the history easier to understand in some workflows.

---

# 7. `--ff-only`

```bash
git merge --ff-only feature
```

Means:

> Perform the merge only if Git can fast-forward. Otherwise abort.

For example:

```text
A---B---C    main
         \
          D---E    feature
```

works.

But:

```text
      C---D    main
     /
A---B
     \
      E---F    feature
```

cannot be fast-forwarded.

Therefore:

```bash
git merge --ff-only feature
```

fails rather than creating a merge commit.

This is useful when you want to prevent automatic merge commits.

---

# 8. Three-way merge

This is the important merge algorithm.

Suppose:

```text
        B---C      main
       /
A-----X
       \
        D---E      feature
```

Git identifies three commits:

```text
       main tip
          ↓
          C

common ancestor
          ↓
          X

feature tip
          ↓
          E
```

Git compares:

```text
X → C
```

and:

```text
X → E
```

Then combines those changes.

Conceptually:

```text
             C
            / \
           /   \
          X     M
           \   /
            \ /
             E
```

This is a **three-way merge**.

The three important points are:

1. **ours/current branch**
    
2. **theirs/branch being merged**
    
3. **common ancestor**
    

---

# 9. Merge conflicts

The most common problem.

Suppose `main` contains:

```java
String name = "Alireza";
```

and `feature` changed the same line to:

```java
String name = "Ali";
```

while `main` changed it to:

```java
String name = "John";
```

Git cannot know which version you want.

You get:

```text
CONFLICT (content): Merge conflict in User.java
```

---

# 10. What conflict markers mean

Git may put this into the file:

```text
<<<<<<< HEAD
String name = "John";
=======
String name = "Ali";
>>>>>>> feature
```

Meaning:

```text
<<<<<<< HEAD
```

Beginning of the **current branch's version**.

```text
=======
```

Separator.

```text
>>>>>>> feature
```

End of the incoming branch's version.

So:

```text
HEAD
 ↓
String name = "John";

        VS

feature
 ↓
String name = "Ali";
```

You decide what the final code should be.

For example:

```java
String name = "Alireza";
```

Then **remove the conflict markers**.

---

# 11. After resolving a conflict

Check:

```bash
git status
```

Then stage the resolved file:

```bash
git add User.java
```

Or all resolved files:

```bash
git add .
```

Then finish the merge:

```bash
git merge --continue
```

Depending on the Git version/workflow, Git may instead simply require:

```bash
git commit
```

The important concept is:

```text
resolve
   ↓
git add
   ↓
finish merge
```

---

# 12. Abort a merge

If you realize:

> "I don't want this merge."

Use:

```bash
git merge --abort
```

Git attempts to restore the repository to the state it had before the merge began.

Example:

```text
Before:

A---B---C    main
     \
      D---E  feature
```

You start:

```bash
git merge feature
```

Conflict happens.

Instead of resolving it:

```bash
git merge --abort
```

You return to your pre-merge state.

### Very important

Do **not** confuse:

```bash
git merge --abort
```

with:

```bash
git reset --hard
```

`reset --hard` is a much more general and potentially destructive operation.

---

# 13. `git merge --continue`

After resolving conflicts:

```bash
git add .
git merge --continue
```

It tells Git:

> "I've resolved the conflicts. Continue the merge."

If Git says there is nothing to continue, check:

```bash
git status
```

Some merge situations can be completed simply with:

```bash
git commit
```

---

# 14. `git merge --no-commit`

```bash
git merge --no-commit feature
```

Normally:

```text
merge
 ↓
merge commit created
```

With `--no-commit`:

```text
merge
 ↓
stop
 ↓
inspect changes
 ↓
git commit
```

Useful when you want to inspect the result before creating the merge commit.

For example:

```bash
git merge --no-commit feature
git diff --cached
```

Then:

```bash
git commit
```

---

# 15. `git merge --squash`

This is different from normal merging.

Suppose:

```text
main:
A---B

feature:
    C---D---E
```

Run:

```bash
git merge --squash feature
```

Git takes the combined changes from `C`, `D`, and `E`, but does **not** create a normal merge relationship.

You might then:

```bash
git commit -m "Add authentication"
```

Result:

```text
A---B---F
```

Where `F` contains the combined changes.

The individual feature commits are not preserved as commits in `main`.

### Normal merge

```text
A---B-------M
     \     /
      C---D
```

### Squash

```text
A---B---F
```

Squashing is useful when you want to turn many development commits into one logical commit.

---

# 16. `git merge --no-edit`

Normally Git generates a merge message such as:

```text
Merge branch 'feature' into main
```

You can accept it without opening the editor:

```bash
git merge --no-edit feature
```

---

# 17. `git merge --edit`

Opposite:

```bash
git merge --edit feature
```

This allows you to edit the merge commit message.

---

# 18. `git merge --stat`

```bash
git merge --stat feature
```

Shows a summary of changed files.

Example:

```text
3 files changed
12 insertions(+)
4 deletions(-)
```

Useful for inspecting what the merge did.

---

# 19. `git merge-base`

This command is extremely useful when learning Git internals.

```bash
git merge-base main feature
```

It finds the **best common ancestor** of the two branches.

Example:

```text
        C
       /
A---B
       \
        D
```

If `B` is their common ancestor:

```bash
git merge-base main feature
```

returns the SHA of `B`.

This is one of the commits Git uses when performing a three-way merge.

---

# 20. `git log --merge`

During conflicts, you can inspect commits relevant to the merge:

```bash
git log --merge
```

Useful for understanding which changes came from the competing histories.

---

# 21. `git diff` during a merge

When you have a conflict:

```bash
git diff
```

shows unresolved differences.

You can also inspect staged changes:

```bash
git diff --cached
```

These are particularly useful before committing.

---

# 22. `git status` is your primary merge diagnostic

When something goes wrong:

```bash
git status
```

Always start here.

During a conflict, Git might tell you:

```text
You have unmerged paths.

both modified: User.java
both modified: SecurityConfig.java
```

This means those files need resolution.

---

# 23. Common problem: uncommitted changes

You try:

```bash
git merge feature
```

and Git says something like:

```text
Your local changes would be overwritten by merge
```

Your working tree contains changes that aren't committed.

Check:

```bash
git status
```

You have three common choices.

### Option 1 — Commit them

```bash
git add .
git commit -m "Save current work"
git merge feature
```

### Option 2 — Stash them

```bash
git stash
git merge feature
git stash pop
```

### Option 3 — Discard them

Only if you're sure:

```bash
git restore .
```

Then:

```bash
git merge feature
```

---

# 24. Common problem: conflict after `git merge`

You see:

```text
CONFLICT (content)
Automatic merge failed
```

Do:

```bash
git status
```

Then:

```text
1. Open conflicted files
2. Resolve conflict markers
3. git add <file>
4. git merge --continue
```

If you want to abandon:

```bash
git merge --abort
```

---

# 25. Common problem: "both modified"

Example:

```text
both modified: src/User.java
```

This means both sides modified the file.

It does **not** necessarily mean the entire file conflicts.

Git may have automatically combined non-conflicting sections and marked only conflicting sections.

Inspect:

```bash
git diff
```

Resolve only the conflicting parts.

---

# 26. Common problem: deleted by us / deleted by them

You may see:

```text
deleted by us: file.txt
```

or:

```text
deleted by them: file.txt
```

This means one side deleted the file while the other modified or retained it.

You need to decide:

### Keep the file

```bash
git add file.txt
```

### Delete the file

```bash
git rm file.txt
```

Then:

```bash
git merge --continue
```

---

# 27. Common problem: accidentally merged the wrong branch

Suppose:

```bash
git switch main
git merge experimental
```

and immediately realize:

> "I didn't mean to do that."

If the merge is **still in progress**:

```bash
git merge --abort
```

If the merge already completed and has not been pushed, you need to inspect your history before choosing a rollback method.

For a merge that created the latest commit, one common approach is:

```bash
git reset --hard HEAD^
```

But be careful: this can discard working-tree changes and changes the branch pointer.

---

# 28. Common problem: merge already pushed

This is where you need to be more careful.

Suppose:

```text
A---B---M  origin/main
```

and other developers may already have fetched `M`.

Don't casually do:

```bash
git reset --hard
git push --force
```

because you're rewriting shared history.

If you need to undo the effects of a merge that is already public, `git revert` is often safer, but reverting a merge requires understanding the mainline parent:

```bash
git revert -m 1 <merge-commit>
```

`-m 1` tells Git which parent should be considered the mainline.

This is an advanced but important distinction:

```text
reset
→ move branch pointer / rewrite local history

revert
→ create a new commit that undoes previous changes
```

---

# 29. Common problem: "Already up to date"

You run:

```bash
git merge feature
```

and get:

```text
Already up to date.
```

This means the current branch already contains everything reachable from `feature`.

For example:

```text
A---B---C    main
         \
          D---E feature
```

If instead:

```text
A---B---C---D---E
             ↑
           main
             ↑
          feature
```

then merging `feature` into `main` has nothing to do.

---

# 30. Common problem: "Already up to date" but you expected changes

Check:

```bash
git branch --show-current
```

Maybe you're on the wrong branch.

Then:

```bash
git log --oneline --graph --decorate --all
```

Also:

```bash
git branch -vv
```

This shows your local branches and their upstream tracking branches.

And if the remote may have changed:

```bash
git fetch
```

Then inspect again.

---

# 31. Remote branch merge

Suppose you want to merge the GitHub version:

```text
origin/feature
```

into your local `main`.

First:

```bash
git fetch origin
```

Then:

```bash
git switch main
git merge origin/feature
```

This is useful because:

```text
git fetch
```

updates your knowledge of the remote without modifying your working branch.

---

# 32. Merge a local branch

```bash
git switch main
git merge feature
```

Simple:

```text
feature
   ↓
   merge
   ↓
main
```

---

# 33. Merge a remote-tracking branch

```bash
git switch main
git fetch origin
git merge origin/feature
```

Here:

```text
origin/feature
```

is **not** the local `feature` branch.

It is a remote-tracking reference.

---

# 34. The standard professional workflow

A typical workflow is:

```bash
git status
git fetch origin
git switch main
git merge feature
```

If successful:

```bash
git status
git log --oneline --graph --decorate --all
```

Then:

```bash
git push
```

If conflicts happen:

```text
git status
      ↓
identify conflicts
      ↓
edit files
      ↓
git add <resolved-files>
      ↓
git merge --continue
      ↓
git status
      ↓
git push
```

Or abandon:

```bash
git merge --abort
```

---

# 35. Merge command cheat sheet

|Command|Purpose|
|---|---|
|`git merge branch`|Merge `branch` into current branch|
|`git merge --no-ff branch`|Always create merge commit|
|`git merge --ff-only branch`|Only allow fast-forward|
|`git merge --no-commit branch`|Merge but stop before commit|
|`git merge --squash branch`|Combine changes without normal merge history|
|`git merge --abort`|Cancel current merge|
|`git merge --continue`|Continue after resolving conflicts|
|`git merge --quit`|Stop merge operation without resetting state|
|`git merge --edit branch`|Edit merge commit message|
|`git merge --no-edit branch`|Use generated message|
|`git merge --stat branch`|Show statistics|
|`git merge --verbose branch`|Verbose merge output|
|`git merge-base A B`|Find common ancestor|
|`git status`|Inspect merge/conflict state|
|`git diff`|Inspect unstaged conflicts/changes|
|`git diff --cached`|Inspect staged resolution|
|`git log --merge`|Inspect commits involved in merge|
|`git log --graph --all`|Visualize history|

---

# 36. The most important distinction

Don't confuse these four concepts:

```text
MERGE
│
├── Fast-forward
│     └── move pointer
│
├── Three-way merge
│     └── combine divergent histories
│
├── Squash merge
│     └── combine changes into one new commit
│
└── Rebase
      └── NOT a merge
          rewrite/replay commits
```

For your Git learning, this graph is worth memorizing:

```text
                    ┌── fast-forward
                    │
                    ├── three-way merge
DIVERGED HISTORY ───┤
                    ├── squash
                    │
                    └── rebase
```

And the most important operational rule:

```text
git merge X
```

always means:

> **Take X and integrate it into the branch I am currently on.**

So whenever you're unsure, first run:

```bash
git status
git branch --show-current
git log --oneline --graph --decorate --all
```

Then decide what you actually want to integrate.


[[0 - Git 🍋‍🟩]]