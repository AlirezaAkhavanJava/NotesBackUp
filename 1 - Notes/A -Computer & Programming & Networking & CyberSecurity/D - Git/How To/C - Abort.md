
There’s no `git --abort` command by itself — it won’t work. You’re probably thinking of **aborting an ongoing operation**, which depends on the command:

---

### 1. Abort a cherry-pick

```bash
git cherry-pick --abort
```

- Cancels the cherry-pick in progress.
    
- Returns your branch to the state before you started cherry-picking.
    

---

### 2. Abort a merge

```bash
git merge --abort
```

- Cancels a merge in progress.
    
- Restores the branch to its pre-merge state.
    

---

### 3. Abort a rebase

```bash
git rebase --abort
```

- Cancels a rebase in progress.
    
- Restores your branch to the state before the rebase started.
    

---

✅ Rule of thumb: `--abort` is **always tied to the command that’s in progress**, it’s not a standalone Git command.


[[0 - Git 🍋‍🟩]]