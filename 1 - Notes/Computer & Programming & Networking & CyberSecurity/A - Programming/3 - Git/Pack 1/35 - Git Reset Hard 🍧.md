


# 🔹 **Git Reset Hard**

---

## **1️⃣ What It Does**

`git reset --hard <commit>`:

1. **Moves HEAD** to the specified commit.
    
2. **Resets the staging area** — all staged changes are discarded.
    
3. **Resets the working directory** — all uncommitted changes are lost.
    

> In short:  
> “Go back to this commit, and erase all changes since then. Pretend nothing else ever happened.”

---

## **2️⃣ Visual Example**

Assume commit history:

```
A — B — C — D  (HEAD -> main)
```

You run:

```bash
git reset --hard B
```

**Result:**

```
HEAD -> B
Staging area: cleared
Working directory: matches B exactly (C & D gone)
```

⚠️ **All changes from C and D are gone** unless saved elsewhere (e.g., stash or reflog).

---

## **3️⃣ Use Cases**

1. **Discard all local changes completely**
    

```bash
# Revert working dir and staging to last commit
git reset --hard HEAD
```

2. **Reset branch to remote state**
    

```bash
git fetch origin
git reset --hard origin/main
```

- Useful if your local branch got messy
    
- Resets everything to match the remote exactly
    

3. **Undo multiple commits permanently (local branch)**
    

```bash
git reset --hard HEAD~2
```

- Deletes last 2 commits
    
- Working directory is restored to state at that time
    

---

## **4️⃣ Example Step-By-Step**

### Initial history

```
A — B — C — D (HEAD)
```

- C & D have changes you no longer want
    

### Step 1: Hard reset

```bash
git reset --hard B
```

- HEAD moves to B
    
- Staging area cleared
    
- Files restored to state of commit B
    
- C & D are gone from history and working directory
    

---

## **5️⃣ Key Points**

- **Dangerous**: All changes after the reset commit are lost unless in stash/reflog
    
- **Does not touch reflog**: You can still recover temporarily using:
    

```bash
git reflog
git reset --hard <old_commit_hash>
```

- **Useful for cleaning mess** or discarding local experiments
    

---

## **6️⃣ Quick ASCII**

```
Before:
A — B — C — D (HEAD)

git reset --hard B

After:
A — B (HEAD)
Staging area: empty
Working directory: same as B
```

---

✅ **Rule of thumb**:

- **Soft** → move branch, keep staged + working files
    
- **Mixed** → move branch, keep working files, unstaged
    
- **Hard** → move branch, discard everything, match commit exactly
    

---

## ⚠️ Git Reset: Understanding the Risks

### What is `git reset`?

`git reset` is a powerful Git command that modifies the commit history and the state of your working directory and staging area. It has three primary modes:

1. **--soft**: Moves the HEAD pointer to a specified commit, keeping changes staged.
    
2. **--mixed** (default): Moves HEAD to a specified commit, keeping changes in the working directory but unstaged.
    
3. **--hard**: Moves HEAD to a specified commit, discarding all changes in the staging area and working directory.
    

### Why is it Dangerous?

- **Data Loss**: Especially with `--hard`, changes can be permanently lost if not committed or stashed.
    
- **History Rewriting**: Using `git reset` on shared branches can rewrite commit history, leading to confusion and potential conflicts for collaborators.
    
- **Irreversible Actions**: Once changes are discarded with `--hard`, they cannot be easily recovered without using Git's reflog or other recovery methods.
    

### Best Practices

- **Avoid Using `--hard`**: Unless absolutely necessary, avoid using `git reset --hard` to prevent accidental data loss.
    
- **Use `git reflog`**: If you accidentally reset and lose commits, `git reflog` can help you recover lost commits.
    
- **Communicate with Team Members**: When working in a team, coordinate with others before using `git reset` to prevent disrupting shared history.
    

---



### Tags : [[0 - Git 🍋‍🟩]]