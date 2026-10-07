
> There comes a time in every developer's life when you want to yoink a commit from a branch, but you don't want to merge or rebase because you don't want _all_ the commits.

The [`git cherry-pick` command](https://git-scm.com/docs/git-cherry-pick) solves this.

## 1. Definition

**`git cherry-pick` takes the changes introduced by a specific commit and applies those changes onto your current branch, creating a new commit.**

In simple terms:

> **"I want that specific commit from over there, but I don't want the rest of that branch."**

Command:

```bash
git cherry-pick <commit-hash>
```

---

# 2. Why does cherry-pick exist?

Imagine this:

```text
main
A --- B ---------------- E
             \
              C --- D
                   fix_bug
```

You're working on `fix_bug`.

Commit `D` contains an important bug fix.

But `C` and the other work on that branch **aren't ready to go into `main`**.

You have a problem:

```text
main
A --- B --- ?
```

You don't want to merge the entire branch because that would bring:

```text
C + D
```

But you only want:

```text
D
```

That's exactly the problem `cherry-pick` solves.

---

# 3. The solution

From `main`:

```bash
git cherry-pick D
```

Git takes the **changes introduced by D**, applies them to your current state, and creates a new commit.

Result:

```text
             C --- D
            /
A --- B --- E --- D'
```

Notice something extremely important:

```text
D ≠ D'
```

`D'` is a **new commit**.

The original `D` still exists on the other branch.

---

# 4. What actually happens internally?

Suppose:

```text
A --- B --- C
          \
           D
```

`D` contains:

```diff
+ fix login validation
```

When you run:

```bash
git cherry-pick D
```

Git conceptually does:

```text
1. Find D's parent
       ↓
2. Calculate:
   D - parent(D)
       ↓
3. Get the patch/diff
       ↓
4. Apply that patch to your current HEAD
       ↓
5. Create a new commit
```

So cherry-pick is fundamentally about **taking a commit's change**, not physically moving the commit.

That's why the resulting commit gets a different hash.

---

# 5. The problem with simply copying the commit

You might think:

> "Why can't Git just move D to main?"

Because a Git commit isn't just a bag of code changes.

A commit contains, among other things:

```text
Commit
├── snapshot/tree
├── parent
├── author
├── committer
├── message
└── metadata
```

The parent of `D` might be `C`:

```text
B --- C --- D
```

But your `main` is:

```text
A --- B
```

If Git simply moved `D`, its parent relationship wouldn't make sense.

So Git creates:

```text
A --- B --- D'
```

where `D'` has `B` as its parent.

---

# 6. Classic real-world situation

Imagine your repository:

```text
main
A --- B --- C
             \
              feature
```

Actually, more clearly:

```text
main:    A --- B

feature:       \
               C --- D --- E
```

Suppose:

```text
C = add authentication
D = redesign dashboard
E = add user profile
```

But authentication is urgently needed on `main`.

The dashboard and profile aren't ready.

You can:

```bash
git switch main
git cherry-pick C
```

Now:

```text
main:    A --- B --- C'

feature:       \ 
               C --- D --- E
```

You got **only the authentication change**.

---

# 7. Cherry-pick vs merge

This distinction is critical.

### Merge

```bash
git merge feature
```

means:

> "Bring the branch's history and changes into my branch."

Example:

```text
A --- B -------- M
     \          /
      C --- D --E
```

You are integrating the branch.

---

### Cherry-pick

```bash
git cherry-pick D
```

means:

> "I specifically want the change introduced by D."

Result:

```text
A --- B --- D'
     \
      C --- D --- E
```

You are selecting **individual commits**.

---

# 8. Cherry-pick vs copy-pasting code

You could technically open the old branch and manually copy the code.

But that causes problems:

```text
copy code manually
       ↓
paste
       ↓
make another commit
```

Git doesn't know that your new change came from the old commit.

Cherry-pick preserves the relationship conceptually:

```text
original commit D
       │
       │ cherry-pick
       ↓
new commit D'
```

Git records information such as:

```text
(cherry picked from commit D)
```

when using the appropriate option:

```bash
git cherry-pick -x D
```

`-x` adds that provenance information to the commit message.

---

# 9. Cherry-pick can cause conflicts

This is where you need to be careful.

Suppose:

```text
main:

A --- B
      \
       changed UserService.java
```

And your target commit also changes the same lines:

```text
feature:

A --- C
      \
       changed same UserService.java
```

You run:

```bash
git cherry-pick C
```

Git may say:

```text
CONFLICT (content): Merge conflict in UserService.java
```

Why?

Because Git can't safely determine how to combine:

```text
current branch's changes
```

with:

```text
cherry-picked commit's changes
```

You resolve the conflict manually.

Then:

```bash
git add UserService.java
git cherry-pick --continue
```

If you decide:

> "Fuck this, I don't want to do this anymore."

you can abort:

```bash
git cherry-pick --abort
```

That returns you to the state before the cherry-pick began.

---

# 10. Multiple commits

You can cherry-pick several commits:

```bash
git cherry-pick A B C
```

Or a range:

```bash
git cherry-pick A..D
```

Be careful:

```bash
A..D
```

means commits **after A through D**, so typically:

```text
B
C
D
```

not A.

---

# 11. When should you use cherry-pick?

### Good use cases

**1. Hotfix**

```text
main
   \
    feature
```

A bug is fixed on `feature`, but the feature itself isn't ready.

Cherry-pick the fix into `main`.

---

**2. Backporting**

You fixed something in a newer branch:

```text
main
release/2.0
release/1.0
```

You want the same bug fix in `release/1.0`.

Cherry-pick the specific fix.

---

**3. Selective integration**

A branch contains:

```text
C = useful
D = unfinished
E = unfinished
```

You only want `C`.

Cherry-pick it.

---

# 12. When should you NOT use it?

Don't use cherry-pick as your default way of integrating entire branches.

If you want:

> "Bring all of this branch's work into my branch."

Usually use:

```bash
git merge
```

or rebase depending on your workflow.

Cherry-picking lots of commits can create duplicated history:

```text
feature:
A --- B --- C --- D

main:
A --- B --- C' --- D'
```

Now you effectively have two versions of the same changes.

That can make future merges more complicated.

---

# 13. The mental model

Remember this:

```text
MERGE
─────
"I want the branch."

        branch
           │
           ▼
        integrate
           │
           ▼
         main
```

```text
CHERRY-PICK
───────────
"I want THIS COMMIT."

feature
   │
   └── D
       │
       │ cherry-pick
       ▼
main ──────── D'
```

And the most important sentence:

> **Cherry-pick does not move a commit. It takes the change introduced by a commit and creates a new commit containing that change on your current branch.**

That is the concept you should have in your head before using the command.


[[Git & Github]]