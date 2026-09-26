
# Git Rebase

## 1. What Is Rebase?

**`git rebase`** is a Git operation that takes the commits from one branch and **replays them on top of another commit or branch**.

Its main effect is to change the **base** of your branch.

In simple terms:

> **Rebase = change where your branch starts from, then replay your commits on top of the new base.**

---

# 2. What Is the Merge Base?

The **merge base** is the commit where two branches most recently shared common history.

For example:

```text
A---B---C  main
     \
      D---E  feature
```

The branches diverged at:

```text
B
```

Therefore:

```text
Merge base = B
```

Git can use this point to determine which commits belong to each branch.

---

# 3. What Does Rebase Change?

Suppose we have:

```text
A---B---C  main
     \
      D---E  feature
```

The feature branch was originally based on `B`.

Now `main` has progressed to `C`.

If we run:

```bash
git switch feature
git rebase main
```

Git produces:

```text
A---B---C---D'---E'  feature
```

The feature commits are now based on `C`.

Therefore:

```text
Before:
merge base = B

After:
merge base = C
```

So, **conceptually, rebase moves the branch's point of divergence forward.**

---

# 4. Does the Merge Base Get a New Commit Hash?

**No.**

The existing commits are not modified.

For example:

```text
A---B---C
     \
      D---E
```

After rebasing:

```text
A---B---C---D'---E'
```

`C` is still exactly the same commit.

Its hash does not change.

The commits that get new hashes are the **replayed commits**:

```text
D → D'
E → E'
```

---

# 5. Why Do D and E Get New Hashes?

A Git commit is identified by a hash calculated from information including its:

- Snapshot/content
    
- Parent commit
    
- Author
    
- Committer
    
- Message
    
- Other commit metadata
    

Originally:

```text
D
└── parent = B
```

After rebase:

```text
D'
└── parent = C
```

Because the parent changed, the commit's identity changes.

Therefore:

```text
D ≠ D'
E ≠ E'
```

Even if the actual changes introduced by `D` and `E` are identical.

---

# 6. How Rebase Actually Works

This is the most important part.

Suppose:

```text
A---B---C  main
     \
      D---E  feature
```

You execute:

```bash
git switch feature
git rebase main
```

Git essentially performs these steps.

## Step 1 — Find the merge base

Git finds the common ancestor:

```text
A---B---C
     \
      D---E
```

Merge base:

```text
B
```

---

## Step 2 — Identify your branch's unique commits

Git determines which commits exist on `feature` but not on `main`.

Those are:

```text
D
E
```

Conceptually:

```text
commits_to_replay = D, E
```

---

## Step 3 — Temporarily remove the branch commits

Git temporarily sets aside the commits that need to be replayed.

Conceptually:

```text
A---B---C  main

D---E      temporarily set aside
```

The original commits are not immediately destroyed.

---

## Step 4 — Move the branch to the new base

Git moves the branch's position to:

```text
C
```

Conceptually:

```text
A---B---C  feature
```

Now `feature` points at the same commit as `main`.

---

## Step 5 — Replay D

Git reapplies the changes introduced by `D` on top of `C`.

This creates a **new commit**:

```text
A---B---C---D'
```

`D'` contains essentially the same change as `D`, but its parent is now `C`.

---

## Step 6 — Replay E

Git then reapplies `E` on top of `D'`.

```text
A---B---C---D'---E'
```

Now `feature` points to `E'`.

---

# 7. What Actually Moves?

This distinction is extremely important.

### Commits don't move.

Git creates new commits.

### The branch pointer moves.

Originally:

```text
A---B---C  main
     \
      D---E  feature
```

`feature` points to:

```text
E
```

After rebase:

```text
A---B---C---D'---E'  feature
```

`feature` now points to:

```text
E'
```

The old commits `D` and `E` still existed initially, but nothing points to them after the rebase. Git can eventually garbage-collect unreachable commits.

---

# 8. Rebase Is Not "Moving Commits"

A common beginner misconception is:

> "Rebase moves D and E."

More accurately:

> **Rebase copies/replays the changes represented by D and E into new commits whose parents are different.**

Think:

```text
D → replay → D'
E → replay → E'
```

rather than:

```text
D → move → D'
```

This distinction explains why commit hashes change.

---

# 9. Why Use Rebase?

One major reason is to maintain a **linear history**.

Without rebase, merging might produce:

```text
A---B---C-------M
     \         /
      D---E---F
```

With rebase:

```text
A---B---C---D'---E'---F'---M
```

Depending on how the merge is performed, you may even be able to fast-forward:

```text
A---B---C---D'---E'---F'
```

The history is easier to read because there is no separate branch line for the feature work.

---

# 10. Rebase vs Merge

Suppose:

```text
A---B---C  main
     \
      D---E  feature
```

And `main` has progressed.

### Merge

```bash
git switch feature
git merge main
```

Produces something conceptually like:

```text
A---B---C-------M
     \         /
      D---E---/
```

The histories are preserved.

### Rebase

```bash
git switch feature
git rebase main
```

Produces:

```text
A---B---C---D'---E'
```

The feature commits are recreated on top of `C`.

### Fundamental difference

**Merge:**

> Combine histories.

**Rebase:**

> Recreate one branch's commits on top of another base.

---

# 11. Rebase Rewrites History

Because:

```text
D → D'
E → E'
```

the commit IDs change.

Therefore, rebase is considered a **history-rewriting operation**.

This is safe when you're working on your own unpublished branch.

For example:

```bash
git switch feature
git rebase main
```

before pushing `feature` is generally straightforward.

---

# 12. The Dangerous Case

Suppose you already pushed:

```text
A---B---D---E  origin/feature
```

Someone else has based their work on `E`.

Then you rebase:

```text
A---B---C---D'---E'
```

Your history now has different commit IDs.

You may need:

```bash
git push --force-with-lease
```

to update the remote branch.

This can disrupt other people's work.

### Rule

> **Avoid rebasing commits that other people are already building on.**

For shared branches, merging is often safer.

---

# 13. Handling Conflicts During Rebase

A rebase can encounter conflicts because Git is trying to replay changes onto a different base.

For example:

```text
A---B---C
     \
      D
```

If `C` and `D` modify the same lines, Git may stop.

You might see:

```text
CONFLICT (content): Merge conflict in file.java
```

Check:

```bash
git status
```

Resolve the conflict manually.

Then:

```bash
git add file.java
```

Continue:

```bash
git rebase --continue
```

Git continues replaying the remaining commits.

---

# 14. Abort a Rebase

If things become messy and you want to return to the state before the rebase:

```bash
git rebase --abort
```

This is extremely useful.

It essentially tells Git:

> "Cancel this rebase and restore my branch to how it was before the rebase started."

---

# 15. Skip a Commit

Sometimes a particular commit cannot or should not be replayed.

You can skip it:

```bash
git rebase --skip
```

Be careful: this discards that commit from the rebased history.

---

# 16. Important Rebase Commands

|Command|Meaning|
|---|---|
|`git rebase main`|Rebase current branch onto `main`|
|`git rebase <commit>`|Rebase onto a specific commit|
|`git rebase --continue`|Continue after resolving a conflict|
|`git rebase --abort`|Cancel the rebase|
|`git rebase --skip`|Skip the current commit|
|`git rebase -i HEAD~N`|Interactive rebase of the last N commits|

---

# 17. Interactive Rebase

Interactive rebase lets you manipulate your commits before sharing them.

Example:

```bash
git rebase -i HEAD~3
```

You might see:

```text
pick abc123 Add User
pick def456 Fix typo
pick ghi789 Fix User validation
```

You can change commands such as:

```text
pick
reword
edit
squash
fixup
drop
```

For example:

```text
pick abc123 Add User
squash def456 Fix typo
squash ghi789 Fix validation
```

This combines commits into a cleaner commit history.

---

# 18. The Mental Model

Think of a branch as a **pointer to a commit**.

```text
main    ──────┐
              ↓
A---B---C
         \
          D---E
               ↑
             feature
```

The branch is not a container holding commits.

It is essentially a movable reference.

When you rebase:

1. Find the merge base.
    
2. Find commits unique to your branch.
    
3. Temporarily set those commits aside.
    
4. Move your branch to the new base.
    
5. Replay the old commits one by one.
    
6. Create new commits.
    
7. Move the branch pointer to the final new commit.
    

Result:

```text
A---B---C---D'---E'
```

---

# 19. The Most Important Facts

```text
REBASE

          find merge base
                 ↓
       identify unique commits
                 ↓
          set them aside
                 ↓
        move to new base
                 ↓
        replay each commit
                 ↓
        create new commits
                 ↓
       move branch pointer
```

Remember these four facts:

1. **Rebase changes the base of a branch.**
    
2. **The old base commit does not get a new hash.**
    
3. **Replayed commits get new hashes because their parents change.**
    
4. **Rebase rewrites history, so be careful with shared branches.**
    

The simplest mental model is:

> **Merge joins two histories. Rebase takes one history's changes and rebuilds them on top of another history.**


[[0 - Git 🍋‍🟩]]