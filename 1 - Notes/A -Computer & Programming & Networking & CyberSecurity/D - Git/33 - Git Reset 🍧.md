



# 🔧 **Git Reset — Complete Guide**

---

## 1️⃣ **What is `git reset`?**

`git reset` is a Git command that **moves the current branch pointer** to a specific commit.  
Depending on options, it can also:

- Keep changes in your working directory
    
- Discard changes in the index (staging area)
    
- Permanently delete commits (danger zone)
    

Think of it as:

> “Tell Git: pretend the branch started from this commit.”

![[Pasted image 20251202151203.png]]

---

## 2️⃣ **Three Modes of `git reset`**

|Mode|What it does|Example effect|
|---|---|---|
|**--soft**|Moves HEAD only, **keeps staging & working dir**|Good for combining commits (amending history)|
|**--mixed** _(default)_|Moves HEAD & **unstages changes**, keeps working dir|Undo a commit but keep changes|
|**--hard**|Moves HEAD, **unstages & deletes all changes**|Completely discards commits & changes — use with caution!|

---

### 🔹 Example Repo

Commits:

```
A - B - C - D  (HEAD -> main)
```

Working dir is clean.

---

### 🔹 Soft Reset

```bash
git reset --soft B
```

Result:

- HEAD moves to B
    
- Commits C & D are now **unstaged commits in index** (staging area)
    
- Working directory unchanged
    

**Use case:**  
Combine last two commits:

```bash
git reset --soft HEAD~2
git commit -m "New combined commit"
```

---

### 🔹 Mixed Reset (Default)

```bash
git reset B
# same as git reset --mixed B
```

- HEAD moves to B
    
- C & D are **unstaged changes** in working dir
    
- Index is cleared (so files are not staged)
    

**Use case:**  
Undo a commit but keep the changes in files for editing.

---

### 🔹 Hard Reset

```bash
git reset --hard B
```

- HEAD moves to B
    
- Staging area cleared
    
- Working directory **changes removed** — lost forever (unless reflog)
    

**Use case:**  
Discard all recent work and reset to a clean state.

---

## 3️⃣ **Undo a Commit Without Losing Changes**

```bash
git reset --soft HEAD~1   # moves branch back one commit, keeps changes staged
git reset HEAD~1          # mixed reset: unstaged changes kept
```

---

## 4️⃣ **Reset a File Instead of Branch**

```bash
git reset HEAD file.txt
```

- Removes `file.txt` from staging area
    
- File remains in working directory
    
- Useful when you accidentally staged something.
    

---

## 5️⃣ **Recovering From a Reset**

- Git keeps old commits in **reflog** temporarily:
    

```bash
git reflog
git reset --hard <old_commit_hash>
```

- This can save you if you accidentally did a `--hard` reset.
    

---

## 6️⃣ **Soft vs Mixed vs Hard — ASCII Visual**

```
Before reset:
HEAD -> D
A - B - C - D

Soft:
HEAD -> B
Staged changes: C, D
Working dir: C, D present

Mixed:
HEAD -> B
Staged changes: none
Working dir: C, D present

Hard:
HEAD -> B
Staged changes: none
Working dir: none
```

---

## 7️⃣ **Reset vs Revert vs Checkout**

|Command|What it does|
|---|---|
|`git reset`|Moves branch pointer, optionally changes staged & working files (rewrites history)|
|`git revert`|Creates a **new commit** that undoes another commit (safe for shared branches)|
|`git checkout <commit>`|Switches working directory to a commit, does not move branch pointer|

💡 Rule of thumb:

- **Reset** → local/private branch, history rewrite
    
- **Revert** → shared/public branch, safe undo
    

---

## 8️⃣ **Danger Zone**

- `git reset --hard` will **delete work permanently** if not committed or in stash.
    
- Never hard reset **shared branches**.
    
- Always check `git status` before reset.
    

---

## 9️⃣ **Practical Use Cases**

1. **Undo last commit but keep changes staged**
    

```bash
git reset --soft HEAD~1
```

2. **Unstage a file accidentally added**
    

```bash
git reset HEAD file.txt
```

3. **Discard local changes completely**
    

```bash
git reset --hard HEAD
```

4. **Reset branch to remote state**
    

```bash
git fetch origin
git reset --hard origin/main
```

---



### Tags : [[0 - Git 🍋‍🟩]]