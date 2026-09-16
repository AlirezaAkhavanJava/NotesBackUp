Here’s each practical **type of Git merge** with its command(s) and the main problems/caveats.

## 1. Fast-forward merge

**Commands**
```bash
git switch main
git merge feature          # fast-forwards if possible
git merge --ff-only feature # fail if fast-forward is not possible
git merge --no-ff feature   # force a merge commit instead
```

**What it does**  
If `main` is an ancestor of `feature`, Git just moves `main` forward to `feature`. No merge commit is created.

**Problems**
- No merge commit, so there’s no record that a feature branch was integrated.
- History looks linear; harder to see where a feature started/ended.
- `git merge --ff-only` fails if branches have diverged:  
  `fatal: Not possible to fast-forward, aborting.`
- You can’t use `git revert -m 1 <merge>` because there is no merge commit.
- Deleting the feature branch makes the integration point invisible.

---

## 2. Three-way / true merge

**Commands**
```bash
git switch main
git merge feature
git merge --no-ff feature   # force a merge commit
git merge -s ort feature    # explicit modern default strategy
```

**What it does**  
Branches have diverged, so Git finds the common ancestor and combines both histories. Creates a merge commit with two parents.

**Problems**
- Merge conflicts are common:  
  `CONFLICT (content): Merge conflict in file.txt`
- You must resolve conflicts manually:
  ```bash
  git status
  # edit files
  git add .
  git commit
  ```
- To abort a conflicted merge:
  ```bash
  git merge --abort
  ```
- Creates non-linear history; can be harder to read.
- Reverting a merge commit is tricky:
  ```bash
  git revert -m 1 <merge-commit>
  ```
  You must choose the correct mainline parent.
- Bad conflict resolution can silently lose changes.
- `ort` can still hit rename/rename or modify/delete conflicts.

---

## 3. Squash merge

**Commands**
```bash
git switch main
git merge --squash feature
git commit -m "Add feature"
```

**What it does**  
Takes all changes from `feature` and stages them as one set of changes. You then make a normal commit. No merge commit, no ancestry link.

**Problems**
- Git does **not** know `feature` was merged.
- Re-merging the same branch later can cause duplicate changes or conflicts.
- Loses individual commit history from the feature branch.
- `git branch --merged` will not show the feature branch as merged.
- Good for a clean `main`, but bad for long-lived branches that keep changing.
- If you forget to commit after `--squash`, you’re left with staged changes.

---

## 4. Octopus merge

**Commands**
```bash
git merge branch1 branch2 branch3
git merge -s octopus branch1 branch2
```

**What it does**  
Merges more than two branches at once. Creates a merge commit with multiple parents.

**Problems**
- Cannot resolve conflicts. If any conflict occurs, the whole merge aborts.
- Only useful for independent, conflict-free branches.
- Creates complex multi-parent history.
- Reverting is difficult because of multiple parents.
- Easy to misuse for normal feature merges.

---

## 5. Ours merge

**Commands**
```bash
git merge -s ours feature
git merge -X ours feature
```

**What it does**
- `-s ours`: records that `feature` was merged, but keeps your current branch’s tree exactly.
- `-X ours`: does a normal merge, but when conflicts occur, favors your current branch.

**Problems**
- `-s ours` completely discards the other branch’s changes. Easy to lose work.
- It still records a merge, so tools may think the branch was merged even though its changes were ignored.
- `-X ours` only affects conflicting hunks. Non-conflicting changes from the other branch still merge in.
- There is no true `-s theirs` strategy. `-X theirs` only affects conflict resolution.

---

## 6. Subtree merge

**Commands**
```bash
git remote add other <url>
git fetch other
git merge -s subtree other/main
# or modern preferred:
git subtree add --prefix=vendor other main --squash
```

**What it does**  
Merges another project/repository into a subdirectory of your repo.

**Problems**
- Often needs `--allow-unrelated-histories`.
- Conflicts are hard because changes are mapped to a path prefix.
- Updating and pushing changes back is complicated.
- `-s subtree` is old and easy to misuse.
- `git subtree` tool is usually preferred for most workflows.
- Easy to merge into the wrong directory.

---

## Merge strategies quick reference

| Strategy | Command | Main problem |
|---|---|---|
| `ort` | `git merge -s ort <branch>` | Default; still can conflict |
| `recursive` | `git merge -s recursive <branch>` | Older default; complex conflicts |
| `resolve` | `git merge -s resolve <branch>` | Simple; fails on complex merges |
| `octopus` | `git merge -s octopus <branches>` | Aborts on any conflict |
| `ours` | `git merge -s ours <branch>` | Discards other branch’s changes |
| `subtree` | `git merge -s subtree <branch>` | Complex path/history handling |

---

## Common fixes

```bash
# Abort a conflicted merge
git merge --abort

# Continue after resolving conflicts
git add .
git commit

# Force a merge commit even when fast-forward is possible
git merge --no-ff feature

# Revert a merge commit
git revert -m 1 <merge-commit>

# Allow merging unrelated histories
git merge --allow-unrelated-histories other/main
```

The main distinction: **fast-forward / three-way / squash** describe the resulting history, while **ort / recursive / octopus / ours / subtree** describe the strategy Git uses to combine content.



[[0 - Git 🍋‍🟩]]