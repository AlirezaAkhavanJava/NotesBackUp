


# 🔹 **Git Reset Soft**

---

## **1️⃣ What It Does**

`git reset --soft <commit>`:

1. **Moves the branch pointer (HEAD)** to the specified commit.
    
2. **Keeps all changes from later commits staged** (in the index).
    
3. **Does not touch the working directory** — your files remain exactly as they were.
    

> In other words:  
> “Pretend I committed only up to this point, but keep everything else ready to recommit.”

---

## **2️⃣ Visual Example**

Assume commit history:

```
A — B — C — D  (HEAD -> main)
```

You run:

```bash
git reset --soft B
```

**Result:**

```
HEAD -> B
Staging area: C & D changes are staged
Working directory: C & D changes present
```

So now you can **combine C and D** into a single commit if you want:

```bash
git commit -m "Combined commit C+D"
```

---

## **3️⃣ Use Cases**

1. **Combine multiple commits**
    

```bash
# Combine last 2 commits
git reset --soft HEAD~2
git commit -m "New combined commit"
```

2. **Undo commit but keep staged changes**
    

```bash
# Undo last commit
git reset --soft HEAD~1
```

- Files stay staged → just re-commit with edits or new message
    

3. **Move commits to a different branch**
    

```bash
git checkout another-branch
git reset --soft HEAD~2
```

- Now the changes can be committed on the new branch.
    

---

## **4️⃣ Example Step-By-Step**

### Initial history

```
A — B — C — D  (HEAD -> main)
```

### Step 1: Soft reset

```bash
git reset --soft C
```

- HEAD moves to C
    
- D changes are staged, ready to commit
    

### Step 2: Commit differently

```bash
git commit -m "Rewrite D differently"
```

- New commit is created based on your staged changes
    

---

## **5️⃣ Key Points**

- **Safe**: Doesn’t touch files in working directory
    
- **Stage-preserving**: Keeps changes staged
    
- **History rewrite**: Moves branch pointer → good for cleaning up recent commits
    
- Can be combined with `git commit --amend` to edit commit messages or combine commits.
    

---

## **6️⃣ Quick ASCII**

```
Before:
A — B — C — D (HEAD)

git reset --soft C

After:
A — B — C (HEAD)
Staged: D changes
Working dir: D changes present
```


### Tags : [[0 - Git 🍋‍🟩]]