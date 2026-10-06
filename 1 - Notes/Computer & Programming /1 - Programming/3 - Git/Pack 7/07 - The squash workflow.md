

## Scenario

You're working on a feature branch:

```bash
git switch -c login
```

You make several commits while developing:

```text
main
 │
 A
 │
 B ── C ── D ── E
              ↑
            login
```

Your commits are:

```text
B: create login controller
C: fix login endpoint
D: fix validation
E: remove debug code
```

These commits make sense **while you're developing**, but you don't necessarily want the final project history to look like:

```text
create login controller
fix login endpoint
fix validation
remove debug code
```

You want one clean commit:

```text
Add login functionality
```

---

# The squash workflow

### 1. Work normally

```bash
git switch -c login
```

Then:

```bash
git add .
git commit -m "create login controller"
```

Later:

```bash
git add .
git commit -m "fix login endpoint"
```

Then:

```bash
git add .
git commit -m "fix validation"
```

And:

```bash
git add .
git commit -m "remove debug code"
```

Your history:

```text
A──B──C──D──E
   ↑        ↑
  main    login
```

---

# 2. Decide what you want to squash

You want to combine the last **4 commits**.

Check them:

```bash
git log --oneline
```

You might see:

```text
e91a2f1 remove debug code
71ac442 fix validation
32bf911 fix login endpoint
8ca22b0 create login controller
a82f991 previous work
```

So:

```bash
git rebase -i HEAD~4
```

---

# 3. Git opens the rebase todo list

You'll see something like:

```text
pick 8ca22b0 create login controller
pick 32bf911 fix login endpoint
pick 71ac442 fix validation
pick e91a2f1 remove debug code
```

Remember:

> This is **not your commit history itself**.  
> It's Git's **instruction list for rebuilding that history**.

Change it to:

```text
pick 8ca22b0 create login controller
squash 32bf911 fix login endpoint
squash 71ac442 fix validation
squash e91a2f1 remove debug code
```

You can use `s` instead of `squash`:

```text
pick 8ca22b0 create login controller
s 32bf911 fix login endpoint
s 71ac442 fix validation
s e91a2f1 remove debug code
```

---

# 4. Save and exit

Git now performs the instructions.

Conceptually:

```text
pick B
```

creates:

```text
B'
```

Then:

```text
s C
```

means:

> Apply C's changes to B' and don't keep C as a separate commit.

Then:

```text
s D
```

same thing.

Then:

```text
s E
```

same thing.

Eventually:

```text
B + C + D + E
        ↓
       B'
```

---

# 5. Git asks for the final commit message

You may get:

```text
# This is a combination of 4 commits.

create login controller

fix login endpoint

fix validation

remove debug code
```

You can clean that up to:

```text
Add login functionality
```

Save and exit.

Now:

```text
Before:

A──B──C──D──E


After:

A──X
   ↑
  login
```

`X` is a **new commit** containing the combined result.

---

# 6. Check your history

```bash
git log --oneline --graph --all
```

You should now see something like:

```text
* 42fd812 Add login functionality
* a82f991 previous work
```

Your four development commits have become one.

---

# 7. Push

If `login` had **never been pushed**:

```bash
git push -u origin login
```

Simple.

If you had already pushed the old history:

```text
Remote:

A──B──C──D──E
```

but you've rewritten it locally:

```text
Local:

A──X
```

then:

```bash
git push --force-with-lease
```

Now remote becomes:

```text
A──X
```

---

# The complete workflow

In practice:

```bash
# Work
git add .
git commit -m "create login controller"

git add .
git commit -m "fix login endpoint"

git add .
git commit -m "fix validation"

git add .
git commit -m "remove debug code"

# Inspect
git log --oneline

# Squash
git rebase -i HEAD~4

# Change:
# pick
# pick
# pick
# pick

# Into:
# pick
# squash
# squash
# squash

# Verify
git log --oneline --graph

# If branch was already pushed
git push --force-with-lease
```

## The important mental model

Don't think:

> "Squash deletes four commits."

Think:

> **"Git takes the changes represented by several commits and reconstructs that part of the history as fewer commits."**

That's why the commit SHA changes.

And the workflow is essentially:

```text
DEVELOP
   ↓
make messy/small commits freely
   ↓
FINISH FEATURE
   ↓
interactive rebase
   ↓
choose pick / squash / fixup
   ↓
Git reconstructs history
   ↓
verify
   ↓
force-with-lease if already pushed
   ↓
CLEAN HISTORY
```

That is the workflow you'll commonly use before merging a feature branch into `main`.


[[Git & Github]]