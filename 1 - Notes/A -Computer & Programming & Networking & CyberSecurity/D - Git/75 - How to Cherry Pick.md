
Cherry-picking in Git means taking **specific commit(s)** from one branch and applying them to another branch. Here’s a clean guide:

---

### 1. Checkout the branch where you want the commit

```bash
git checkout target-branch
```

---

### 2. Cherry-pick a single commit

```bash
git cherry-pick <commit-hash>
```

- `<commit-hash>` is the SHA of the commit you want.
    
- This will apply that commit to your current branch.
    

---

### 3. Cherry-pick multiple commits

You have a few options:

- **Consecutive commits**:
    

```bash
git cherry-pick <start-commit>^..<end-commit>
```

- **Specific non-consecutive commits**:
    

```bash
git cherry-pick <commit1> <commit2> <commit3>
```

---

### 4. Resolving conflicts

If there are conflicts:

1. Git will pause and mark files as conflicted.
    
2. Fix the conflicts manually.
    
3. Stage the resolved files:
    

```bash
git add <file>
```

4. Continue the cherry-pick:
    

```bash
git cherry-pick --continue
```

- To abort:
    

```bash
git cherry-pick --abort
```

---

### 5. Tips

- Cherry-pick creates a **new commit** with the same changes.
    
- Use it for applying **specific fixes or features** without merging a whole branch.
    

---


##### tags : [[0 - Git 🍋‍🟩]]