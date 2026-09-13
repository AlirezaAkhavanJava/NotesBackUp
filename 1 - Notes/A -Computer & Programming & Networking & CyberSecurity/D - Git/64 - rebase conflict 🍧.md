
Git rebase conflicts occur when Git can't automatically merge changes during a `git rebase` because the same parts of a file were modified in both the branch you're rebasing onto and your current branch.

Here's a complete step-by-step guide to **resolve rebase conflicts**:

---

### 1. **Start the Rebase**
```bash
git checkout feature-branch
git rebase main
```
→ If conflicts occur, Git stops at the problematic commit.

---

### 2. **Check Status**
```bash
git status
```
You’ll see:
```
rebase in progress; onto abc1234
You are currently rebasing branch 'feature-branch' on 'abc1234'.
(unresolved conflicts in files)
```

---

### 3. **Identify Conflicted Files**
Git marks conflicts inside files with:
```diff
<<<<<<< HEAD
Changes from the branch you're rebasing onto (e.g., main)
=======
Your changes from the feature branch
>>>>>>> your-commit-hash
```

Open each conflicted file in your editor.

---

### 4. **Resolve Conflicts Manually**
Edit the file to keep the desired changes. Remove the `<<<<<<<`, `=======`, `>>>>>>>` markers.

Example **before**:
```js
<<<<<<< HEAD
console.log("Hello from main");
=======
console.log("Hello from feature");
>>>>>>> feature-commit
```

**After resolution** (choose one or combine):
```js
console.log("Hello from both!");
```

Save the file.

---

### 5. **Stage Resolved Files**
```bash
git add file1.js file2.js
# or
git add .
```

---

### 6. **Continue the Rebase**
```bash
git rebase --continue
```

→ Git applies the next commit. Repeat steps 3–6 if more conflicts arise.

---

### 7. **Abort (if needed)**
To cancel the rebase and return to original state:
```bash
git rebase --abort
```

---

### Pro Tips

| Tip | Command |
|-----|---------|
| See which commits are being rebased | `git log --oneline main..feature-branch` |
| Skip a problematic commit | `git rebase --skip` |
| Use merge tool (e.g., VS Code, meld) | `git mergetool` |
| Interactive rebase (safer) | `git rebase -i main` |

---

### Example Full Flow
```bash
git checkout feature
git rebase main

# Conflict! Edit files...
git add .
git rebase --continue

# Done? Push with force
git push --force-with-lease
```

> **Warning**: Use `--force-with-lease` (not `--force`) to avoid overwriting others' work.

---



#### Tags : [[0 - Git 🍋‍🟩]]