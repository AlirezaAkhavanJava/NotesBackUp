
Before trying to **rebase**, you should prepare your repository so the operation is safe and predictable.

Think of rebase as:

> "Take my commits, temporarily remove them, move my branch to another point, then replay my commits on top."

Because Git is rewriting history, preparation matters.

---

## 1. Check your current branch

```bash
git branch
```

Example:

```
  main
* feature/login
```

Make sure you are rebasing the correct branch.

---

## 2. Check your working tree

```bash
git status
```

You want:

```
nothing to commit, working tree clean
```

If you have changes:

### Option A: Commit them

```bash
git add .
git commit -m "save work before rebase"
```

### Option B: Stash them

```bash
git stash
```

Later:

```bash
git stash pop
```

---

## 3. Update the branch you will rebase onto

Usually you rebase your feature branch onto the latest `main`.

First update `main`.

```bash
git switch main
git pull
```

Now main is fresh.

---

## 4. Switch back to your feature branch

```bash
git switch feature/login
```

---

## 5. Check the history

Before rebasing, visualize:

```bash
git log --oneline --graph --all
```

Example:

```
* c3d4e5 feature: add login
* b2c3d4 feature: add controller
|
* a1b2c3 main
* 999888 initial
```

You understand where your commits are.

---

## 6. Create a safety backup branch (recommended)

Because rebase rewrites commits:

```bash
git branch backup-before-rebase
```

Now if something goes wrong:

```bash
git switch backup-before-rebase
```

Your old history is still there.

---

## 7. Fetch remote changes

If working with GitHub:

```bash
git fetch origin
```

This updates your remote references without changing your files.

---

## 8. Start the rebase

Example:

```bash
git rebase main
```

Meaning:

```
Before:

main
 A---B---C
          \
           D---E feature


After:

main
 A---B---C---D'---E' feature
```

`D` and `E` are recreated as new commits (`D'`, `E'`).

---

# During conflicts

Git stops:

```
CONFLICT (content): Merge conflict in file.java
```

Check:

```bash
git status
```

Fix files.

Then:

```bash
git add file.java
git rebase --continue
```

If you want to abandon:

```bash
git rebase --abort
```

You return exactly to before the rebase.

---

# After successful rebase

Check:

```bash
git log --oneline --graph
```

Then run tests/build:

Example Java:

```bash
mvn test
```

or

```bash
./mvnw test
```

---

# Safe rebase workflow

The professional habit:

```bash
git status

git fetch origin

git branch backup-before-rebase

git log --oneline --graph --all

git rebase main

# resolve conflicts if needed

git push --force-with-lease
```

Important:

Use:

```bash
git push --force-with-lease
```

not:

```bash
git push --force
```

because `--force-with-lease` protects other people's new commits on the remote branch.


[[Git & Github]]