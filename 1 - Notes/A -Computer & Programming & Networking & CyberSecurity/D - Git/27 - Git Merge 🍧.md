


## **1. What is `git merge`?**

`git merge` is a **Git command** used to integrate changes from one branch into another. Essentially, it allows you to combine the histories of two branches.

- **Branches**: Separate lines of development in Git.
    
- **Merging**: Combining the changes from different branches.
    

Think of it like this:

- You have a `main` branch (stable code) and a `feature` branch (new functionality). When the feature is ready, you want to bring those changes into `main`. That’s what `git merge` does.
    

---

## **2. Types of Merges**

### **A. Fast-forward merge**

- Happens when the branch being merged has **no new commits since branching**.
    
- Git just moves the pointer forward, no extra merge commit is created.
    

```bash
git checkout main
git merge feature
```

**Example:**

```
main: A---B
feature:     C---D
```

After fast-forward merge:

```
main: A---B---C---D
```

- No conflicts here, very straightforward.
    

---

### **B. Recursive (3-way) merge**

- Happens when **both branches have new commits**.
    
- Git compares the **common ancestor**, the current branch, and the branch to merge → merges changes.
    
- May create a **merge commit**.
    

```bash
git checkout main
git merge feature
```

**Example:**

```
main:    A---B---C
feature:      B---D
```

After merge:

```
main:    A---B---C---M
                     /
feature:           D
```

- `M` is the merge commit.
    
- If changes overlap, **merge conflicts** may occur.
    

---

### **C. Merge conflicts**

- Occur when the same lines of a file are changed differently in two branches.
    
- Git stops the merge and asks you to **resolve conflicts manually**.
    

```bash
git merge feature
# Git shows conflict markers like <<<<<<< HEAD
```

After resolving conflicts:

```bash
git add <file>
git commit
```

---

## **3. Merge strategies**

Git has several merge strategies:

1. **recursive** (default for 2 branches)
    
    - Uses 3-way merge, can handle multiple merge bases.
        
2. **ours**
    
    - Keeps your branch changes, ignores the other branch.
        
3. **theirs**
    
    - Opposite of ours; discards your branch changes, keeps theirs.
        
4. **octopus**
    
    - For merging more than 2 branches at once.
        
5. **resolve**
    
    - Simpler than recursive, cannot handle criss-cross merges.
        

**Example:**

```bash
git merge -s ours feature
```

- This keeps the current branch content entirely.
    

---

## **4. Options for git merge**

- `--no-ff`: Force a merge commit, even if fast-forward is possible.
    
- `--ff-only`: Only allow fast-forward merges; abort if merge commit is required.
    
- `--squash`: Combines all commits from the branch into **one commit**.
    
- `--abort`: Abort the merge in case of conflicts.
    

```bash
git merge --no-ff feature
```

- Forces a merge commit even if the branch can fast-forward. Good for keeping history explicit.
    

---

## **5. Merge vs Rebase**

- **Merge**: Keeps history of branches, creates a merge commit.
    
- **Rebase**: Moves your branch commits on top of another branch, **linearizes history**, no merge commit.
    

```bash
git checkout feature
git rebase main
```

- After rebase, history looks linear.
    
- Merge is safer when collaborating; rebase is cleaner for local work.
    

---

## **6. Complete Example**

```bash
# Initialize repo
git init myrepo
cd myrepo

# Create a main branch and a file
echo "Hello" > file.txt
git add file.txt
git commit -m "Initial commit"

# Create feature branch
git checkout -b feature
echo "Feature work" >> file.txt
git commit -am "Add feature"

# Switch back to main
git checkout main
echo "Main branch update" >> file.txt
git commit -am "Update main"

# Merge feature into main
git merge feature
```

- If there’s no conflict → simple merge commit.
    
- If conflict → Git shows conflict markers `<<<<<<<` → resolve → `git add file.txt` → `git commit`.
    

---

## **7. Visualization**

```
      main
A---B---C
     \    
      D---E feature
```

- Merge results in:
    

```
      main
A---B---C---M
     \    /
      D---E feature
```

`M` = merge commit.

---

## **8. Advanced Tips**

1. **Abort merge**:
    
    ```bash
    git merge --abort
    ```
    
2. **Merge specific commits**:
    
    ```bash
    git cherry-pick <commit_hash>
    ```
    
3. **Interactive merge tool**:
    
    ```bash
    git mergetool
    ```
    
4. **Check what would merge without committing**:
    
    ```bash
    git merge --no-commit --no-ff feature
    ```
    

---

## ✅ **Summary**

- `git merge` integrates branches.
    
- Two main types: **fast-forward** and **3-way merge**.
    
- Conflicts may arise, must be resolved manually.
    
- Merge strategies (`ours`, `theirs`, `octopus`) help in complex scenarios.
    
- Options like `--no-ff`, `--squash` control the merge behavior.
    
- Merge keeps branch history, rebase linearizes it.
    

---



# **🐐 Git Merge Cheat Sheet**


## **1. Merge Basics**

### **Command**

```bash
git merge <branch_name>
```

- Integrates `<branch_name>` into the **current branch**.
    
- Creates a **merge commit** if needed.
    

**Branches example**:

```
main:    A---B
feature:     C---D
```

Merge `feature` into `main`:

```
git checkout main
git merge feature
```

Result (fast-forward possible):

```
main: A---B---C---D
```

---

## **2. Types of Merges**

|Type|What it does|Example|
|---|---|---|
|**Fast-forward**|Moves branch pointer forward, no merge commit|`main: A---B`, `feature: C` → merge → `main: A---B---C`|
|**Three-way merge**|Combines diverged histories, may create commit|`main: A---B---C`, `feature: B---D` → merge → `main: A---B---C---M`|
|**Squash merge**|Combines all commits into 1, no history|`git merge --squash feature`|
|**Ours**|Keeps **current branch**, discards other branch|`git merge -s ours feature`|
|**Theirs**|Keeps **other branch**, discards current branch|`git merge -s theirs feature`|
|**Octopus**|Merge **multiple branches** at once|`git merge branch1 branch2 branch3`|

---

## **3. Merge Options**

|Option|Description|
|---|---|
|`--no-ff`|Always create a merge commit, even if fast-forward possible|
|`--ff-only`|Only fast-forward merges allowed|
|`--squash`|Combine commits into one|
|`--abort`|Abort the merge if conflicts|
|`--no-commit`|Perform merge but don’t commit automatically|
|`-X ours / -X theirs`|Resolve conflicts preferring ours/theirs|

---

## **4. Merge Conflicts**

- Happens when same lines in a file differ.
    
- Git inserts conflict markers:
    

```text
<<<<<<< HEAD
Main branch content
=======
Feature branch content
>>>>>>> feature
```

**Steps to resolve:**

1. Open the file, fix content manually.
    
2. Add file to staging:
    

```bash
git add <file>
```

3. Commit merge:
    

```bash
git commit
```

- Or use **merge tool**:
    

```bash
git mergetool
```

---

## **5. Merge Workflow Example**

```bash
# 1. Start on main
git checkout main

# 2. Merge feature
git merge feature

# 3. Resolve conflicts if any
git add file.txt
git commit
```

**Branches visualization**:

Before merge:

```
main:    A---B---C
feature:      D---E
```

After merge:

```
main:    A---B---C---M
                 /
feature:      D---E
```

`M` = merge commit.

---

## **6. Advanced Tips 🐐**

- **Abort merge**:
    

```bash
git merge --abort
```

- **Merge specific commit**:
    

```bash
git cherry-pick <commit_hash>
```

- **Preview merge without committing**:
    

```bash
git merge --no-commit --no-ff feature
```

- **Force merge commit**:
    

```bash
git merge --no-ff feature -m "Merge feature branch"
```

- **Use ours/theirs for conflicts automatically**:
    

```bash
git merge -X ours feature
git merge -X theirs feature
```

---

## **7. Merge vs Rebase (Cheat)**

|Feature|Merge|Rebase|
|---|---|---|
|History|Branches preserved|Linearized|
|Merge commit|Yes|No|
|Collaboration|Safe for shared branches|Risky if shared|
|Command|`git merge feature`|`git rebase main`|

---

## **8. Quick Visual Memory 🐐**

```
Fast-forward (no diverge):
main: A---B
feature:    C
→ merge → main: A---B---C

3-way merge (diverged):
main:    A---B---C
feature:      D---E
→ merge → main: A---B---C---M
                 /  
             D---E
```

Conflict markers: `<<<<<<< HEAD` … `=======` … `>>>>>>> feature`

---


### Tags : [[0 - Git 🍋‍🟩]]