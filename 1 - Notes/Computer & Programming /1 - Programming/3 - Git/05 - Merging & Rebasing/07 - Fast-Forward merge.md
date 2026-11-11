


## 1. The scenario

You pull `main` and see it's at commit `a1b2c3d`. Your task: fix a null-pointer bug in `UserService.java`. You create a branch and commit twice:

```bash
git switch -c fix_bug
# edit UserService.java
git commit -am "Add null check in getUser"        # c3f9e21
# edit UserServiceTest.java
git commit -am "Add test for missing user"        # d4a8b07
```

You feel good. You go to lunch.

When you come back, Slack is on fire. A teammate, Priya, merged a refactor into `main` while you were away. She renamed a method in `UserService.java`, the exact file you touched. You run `git fetch`, and `main` now sits at `e7c5f90`.

Your team's rule: **`main` must have a straight-line history, no merge commits.** So a normal `git merge` is off the table. You need to get your work onto `main` in a way that slides in cleanly. That's what this workflow is for.

## 2. The core mental model

**A fast-forward merge can only move a branch label forward along a straight line. So before you merge, you use rebase to _make_ your branch a straight-line extension of `main`.**

Rebase fixes the _shape_ of history. Fast-forward then does the _delivery_.

## 3. Step-by-step walkthrough

Let's build the mental model one state at a time. Remember: a branch is just a movable label pointing at a commit.

**Step 1: where you started**

```
a1b2c3d ← main
    \
     c3f9e21 ← d4a8b07 ← fix_bug
```

Simplified:

```
A---(main)
     \
      C---D   (fix_bug)
```

At this point, `main` is an **ancestor** of `fix_bug` (you can walk backward from D and reach A). That means a fast-forward would be possible: Git would just slide the `main` label to D.

**Step 2: Priya's merge lands**

```
A---E          (main)
 \
  C---D        (fix_bug)
```

The histories have **diverged**. `main` has E (which you don't have). `fix_bug` has C and D (which `main` doesn't have).

Now try to fast-forward:

```bash
git switch main
git merge --ff-only fix_bug
```

Git replies:

```
fatal: Not possible to fast-forward, aborting.
```

Why? Sliding `main` to D would drop E from history. Git refuses to lose Priya's work. A fast-forward requires that `main`'s tip be an ancestor of the branch you're merging, and E isn't.

**Step 3: you rebase**

```bash
git switch fix_bug
git rebase main
```

Rebase does this: it finds your commits (C, D), temporarily sets them aside, moves your branch base to E, then **replays** each commit on top, one at a time.

```
A---E                 (main)
     \
      C'---D'         (fix_bug)
```

C' and D' are **new commits**. Same changes, but a new parent means a new hash. `c3f9e21` becomes, say, `9b2e4a1`. The old C and D still exist in Git's storage for a while, but nothing points at them.

**Step 4: fast-forward**

```bash
git switch main
git merge --ff-only fix_bug
```

Now `main` (E) is an ancestor of `fix_bug` (D'), so Git slides the label:

```
A---E---C'---D'       (main, fix_bug)
```

No merge commit. One straight line. Delivered.

## 4. The tricky moment: the conflict

In step 3, it doesn't go smoothly. Git prints:

```
Auto-merging src/UserService.java
CONFLICT (content): Merge conflict in src/UserService.java
error: could not apply 9b2e4a1... Add null check in getUser
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
```

Why can't Git decide? Priya renamed `getUser` to `findUser` on the exact lines where you added your null check. Git sees two different edits to the same lines. It has no way to know whether the correct result is her name with your check, your version, or something else. That's a human judgment.

Open the file:

```java
<<<<<<< HEAD
public User findUser(long id) {
    return repo.find(id);
=======
public User getUser(long id) {
    if (id <= 0) throw new IllegalArgumentException();
    return repo.find(id);
>>>>>>> c3f9e21 (Add null check in getUser)
```

**Warning: rebase flips the labels.** `HEAD` here is `main` plus Priya's work (what you're rebasing _onto_), and the bottom half is _your_ commit being replayed. In a merge it's the opposite.

## 5. Resolution

You want her new name and your check:

```java
public User findUser(long id) {
    if (id <= 0) throw new IllegalArgumentException();
    return repo.find(id);
```

Then:

```bash
git diff --check                 # no leftover markers?
git add src/UserService.java     # "this path is resolved"
git rebase --continue
```

Why `git add`? A commit is built from the staging area, and `add` is how you tell Git the conflict is resolved.

State during the pause:

```
A---E---C'             (HEAD detached, rebase in progress)
         \
          (D waiting to be replayed)
```

After `--continue`, D replays (cleanly this time) and you get:

```
A---E---C'---D'        (fix_bug)
```

Then you run the fast-forward from step 4.

## 6. Advanced example: three commits, repeated conflicts, and a push

Same day, harder situation. You have **three** commits on `fix_bug`, and `fix_bug` is **already pushed** to `origin` because you opened a pull request.

```
A---E                  (main)
 \
  C---D---F            (fix_bug, origin/fix_bug)
```

- C: rename a variable in `UserService.java`
- D: add null check in the same area
- F: update `UserServiceTest.java`

**Problem 1: the conflict can repeat.**  
Rebase replays commit by commit. C conflicts with E. You resolve it. Then D touches the same lines, and may conflict _again_ against C'. You can face the same area two or three times.

This is where `git rerere` earns its keep:

```bash
git config rerere.enabled true
```

Git records each resolution and replays it if the identical conflict returns. Useful for abort-and-retry too: if you botch the rebase, run `git rebase --abort`, and next time recorded fixes apply themselves.

**Problem 2: the push is rejected.**  
After the rebase:

```
A---E---C'---D'---F'  (fix_bug, local)
 \
  C---D---F           (origin/fix_bug, remote, now divergent)
```

Your local `fix_bug` and `origin/fix_bug` no longer share the commits C, D, F (they have new hashes). A plain `git push` fails:

```
! [rejected] fix_bug -> fix_bug (non-fast-forward)
```

Notice: it's the same "can't fast-forward" rule, now applied to the _remote_. You must overwrite it:

```bash
git push --force-with-lease origin fix_bug
```

**Why `--force-with-lease` and not `--force`?** It says: "overwrite the remote branch _only if_ it's still where I last saw it." If a reviewer pushed a fixup commit in the meantime, plain `--force` would silently delete it. With the lease, Git refuses and you fetch first.

**Invariants to keep in mind:**

1. Rebase never edits commits. It creates _copies_ with new parents.
2. A fast-forward moves a label and creates _nothing_.
3. After rebase, your branch's old commits are unreachable but recoverable via `git reflog`.

**What could go wrong:**

- A coworker based `fix_review` on your pushed `fix_bug`. After your force-push, their branch points at orphaned commits, and they get duplicate commits or confusing conflicts when they pull.
- You resolve a conflict wrongly in C', and the mistake silently propagates because D' and F' build on it. Test after each `--continue` if it's risky.
- You run `git add .` and accidentally stage an unrelated file into the replayed commit.

**What if `main` moves again while your PR is open?**  
Then the fast-forward fails again, because `main` diverged once more. You rebase again. This is the cost of the workflow: on busy repos, you race other people for the tip of `main`. Many teams solve it with a merge queue, which automates "rebase, test, fast-forward" in order.

**What if you want to abort?**  
Mid-rebase, `git rebase --abort` returns everything to exactly how it was before you started. Nothing is lost.

## 7. Contrastive comparison: rebase + ff vs. merge commit

Starting state:

```
A---E             (main)
 \
  C---D           (fix_bug)
```

**Approach 1: rebase, then fast-forward**

```bash
git switch fix_bug && git rebase main
git switch main && git merge --ff-only fix_bug
```

```
A---E---C'---D'   (main)
```

**Approach 2: merge commit**

```bash
git switch main
git merge --no-ff fix_bug
```

```
A---E-------M     (main)
 \         /
  C-------D
```

M is a **merge commit** with two parents.

||Rebase + ff|Merge commit|
|---|---|---|
|History shape|Straight line|Branches and joins|
|Rewrites commits|Yes (new hashes)|No|
|Conflicts resolved|Per replayed commit, on your branch|Once, in the merge commit|
|Records "this was a branch"|No|Yes|
|Safe on shared branches|No|Yes|
|`git bisect` / `git revert`|Simple|Needs `-m` to revert a merge|

**When to use which:**

- Rebase + ff: your own short-lived feature branch, team wants linear history.
- Merge commit: a long-lived shared branch, or you want an explicit record of the feature as a unit.
- Never rebase a branch others already build on, unless everyone agrees.

## 8. Key mental model recap

- A fast-forward only **moves a label**. It's possible only when the target is an ancestor of the source.
- If `main` moved, histories **diverged**, so fast-forward is impossible.
- Rebase **replays** your commits on top of the new `main`, restoring the straight line.
- Replayed commits are **copies with new hashes**, which is why pushed branches need `--force-with-lease`.
- Conflicts mean Git can't choose between two edits to the same lines. You decide, `git add`, `git rebase --continue`.
- `--ff-only` is your guardrail: it fails instead of silently making a merge commit.

```
        start feature branch
                |
                v
        work + commit on feature
                |
                v
        has main moved? --no--> fast-forward main
                |                      |
               yes                     v
                |                    done
                v
        git rebase main
                |
                v
        conflict? --yes--> edit, git add, rebase --continue
                |                      |
               no <--------------------+
                |
                v
        already pushed? --yes--> push --force-with-lease
                |                      |
               no <--------------------+
                |
                v
        git merge --ff-only feature
                |
                v
              done
```

**Takeaway:** Rebase reshapes your branch into a straight line on top of `main`, so the final merge is nothing more than sliding a label forward.




[[Git & Github]]