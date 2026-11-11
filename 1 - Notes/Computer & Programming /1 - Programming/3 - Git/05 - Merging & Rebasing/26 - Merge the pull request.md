
Once the PR exists, you have two ways to merge it: **GitHub GUI** or **GitHub CLI**.

Assume:

```text
main          ← target
   ↑
add_scanner   ← PR branch
```

## 1. Merge through GitHub GUI

Open the repository on GitHub and go to:

**Pull requests → your PR**

At the bottom of the PR, you'll see the merge controls.

Usually you'll have options such as:

- **Create a merge commit**
    
- **Squash and merge**
    
- **Rebase and merge**
    

### Create a merge commit

Click:

**Merge pull request → Confirm merge**

History becomes:

```text
A──B────────M
    \      /
     C──D
```

`M` is the merge commit.

---

### Squash and merge

Click the dropdown next to the merge button and choose:

**Squash and merge**

History becomes:

```text
A──B──X
```

where `X` contains all the changes from the PR.

This is useful when your branch contains development commits like:

```text
add scanner
fix scanner
fix scanner again
remove debug
fix typo
```

and you want `main` to have:

```text
Add scanner functionality
```

---

### Rebase and merge

GitHub takes the commits from your PR and puts them directly on top of `main`:

```text
Before:

A──B
    \
     C──D

After:

A──B──C'──D'
```

No merge commit is created.

---

# 2. Merge through CLI

With GitHub CLI:

```bash
gh pr list
```

Find the PR number:

```text
#12  Add scanner functionality
```

Then:

```bash
gh pr merge 12
```

GitHub CLI will ask which merge method you want.

You can explicitly choose one.

### Merge commit

```bash
gh pr merge 12 --merge
```

### Squash

```bash
gh pr merge 12 --squash
```

### Rebase

```bash
gh pr merge 12 --rebase
```

---

## 3. Automatically delete the branch

You can also tell GitHub to delete the remote PR branch after merging:

```bash
gh pr merge 12 --squash --delete-branch
```

For example, your complete workflow could be:

```bash
git switch add_scanner

# work
git add .
git commit -m "Add scanner functionality"

git push -u origin add_scanner

gh pr create --base main --head add_scanner

# after review
gh pr merge --squash --delete-branch
```

---

## Which merge method should you use?

For a normal feature branch, I would generally use:

```bash
gh pr merge <PR-number> --squash --delete-branch
```

if your project wants a **clean, linear `main` history**:

```text
main

A──B──C──D
         ↑
    Add scanner
```

Instead of:

```text
A──B──────M
    \    /
     C──D
```

The key distinction is:

```text
Merge commit
    → preserves the branch structure

Squash
    → turns the entire PR into one commit

Rebase
    → preserves individual commits but removes the merge commit
```

One important detail: **the merge strategy is a repository/team policy**, so if you're contributing to someone else's repository, follow whatever strategy that project uses.


[[Git & Github]]