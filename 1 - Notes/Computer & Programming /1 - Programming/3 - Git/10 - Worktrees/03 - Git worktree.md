
**`git worktree` is a different concept from the working tree we just discussed.**

## 1. What is a Git worktree?

A **Git worktree** lets you have **multiple working directories for the same Git repository**, each checked out to a different branch/commit.

Normally you have:

```text
megacorp/
├── .git/
├── scripts/
└── ...
```

and one checkout:

```text
HEAD → main
       ↓
   working tree
```

With worktrees:

```text
megacorp/              → main
megacorp-fix/          → fix_bug
megacorp-experiment/   → experiment
```

All three are connected to the **same Git repository**.

---

# 2. Why would you want one?

Suppose you're working on:

```text
main
```

but you want to inspect/fix another branch.

Normally you'd do:

```bash
git switch fix_bug
```

But now your `main` files disappear and are replaced by `fix_bug`'s files.

A worktree lets you have both simultaneously:

```text
/mnt/hdd/.../megacorp
        ↓
      main

/mnt/hdd/.../megacorp-fix
        ↓
      fix_bug
```

You can work in both directories at the same time.

---

# 3. Create your first worktree

From your repository:

```bash
cd "/mnt/hdd/Home/Programming Files/Git/megacorp"
```

Then:

```bash
git worktree add ../megacorp-fix fix_bug
```

Meaning:

```text
git worktree add
    ↑
create another working directory

../megacorp-fix
    ↑
where to create it

fix_bug
    ↑
branch to check out there
```

You'll get:

```text
Programming Files/Git/
├── megacorp/
│   └── main
│
└── megacorp-fix/
    └── fix_bug
```

---

# 4. What if the branch doesn't exist?

You can create the branch **and** the worktree simultaneously:

```bash
git worktree add -b experiment ../megacorp-experiment
```

This means:

```text
create branch: experiment
             +
create worktree: ../megacorp-experiment
             +
checkout experiment there
```

So:

```text
megacorp/
    ↓
main

megacorp-experiment/
    ↓
experiment
```

---

# 5. See your worktrees

Run:

```bash
git worktree list
```

Example:

```text
/mnt/hdd/.../megacorp             b6c5f1b [main]
/mnt/hdd/.../megacorp-fix         30f59b3 [fix_bug]
/mnt/hdd/.../megacorp-experiment  a9b350f [experiment]
```

This is very useful because Git is telling you:

```text
directory              commit      branch
────────────────────────────────────────────
megacorp                b6c5f1b     main
megacorp-fix            30f59b3     fix_bug
megacorp-experiment     a9b350f     experiment
```

---

# 6. The important internal idea

A normal Git repository has one working tree:

```text
.git
 │
 └── working tree
```

With worktrees:

```text
                 Git repository
                  /     |     \
                 /      |      \
                ↓       ↓       ↓
             worktree worktree worktree
              main     fix      experiment
```

Git stores the repository's object database centrally, while each worktree has its own checkout state.

That's why you **don't duplicate the entire Git history** every time you create a worktree.

---

# 7. Important restriction

You generally **cannot check out the same branch in two worktrees simultaneously**.

For example:

```bash
git worktree add ../another-main main
```

while `main` is already checked out in `megacorp` will normally fail.

Why?

Because then you would have:

```text
megacorp/
    main
       ↑
       └── same branch

another-main/
    main
       ↑
       └── same branch
```

and Git would have ambiguity about where that branch's `HEAD` is supposed to be.

Instead:

```text
megacorp/       → main
another-main/   → other_branch
```

---

# 8. Worktree vs branch

This distinction is important:

**Branch:**

```text
fix_bug
```

is a movable reference pointing to commits.

**Worktree:**

```text
../megacorp-fix/
```

is an actual directory containing checked-out files.

So:

```text
Branch
  ↓
points to commit

Worktree
  ↓
provides filesystem checkout
```

You can have many worktrees attached to one repository.

---

# 9. Removing a worktree

When you're finished:

```bash
git worktree remove ../megacorp-fix
```

This removes the worktree directory.

It **does not automatically delete the branch**.

So afterward:

```text
fix_bug
```

can still exist as a branch.

If you also want to delete the branch:

```bash
git branch -d fix_bug
```

---

## The mental model

Remember this:

```text
                ONE GIT REPOSITORY
                       │
          ┌────────────┼────────────┐
          ↓            ↓            ↓
       Worktree     Worktree     Worktree
          │            │            │
        main         fix_bug     experiment
          │            │            │
          ↓            ↓            ↓
       files          files        files
```

**`git worktree add` = "Give me another directory connected to this repository, checked out at this branch/commit."**

And this becomes particularly useful with **Git bisect, debugging, parallel feature work, comparing branches, and running different versions of a project simultaneously.**


[[Git & Github]]