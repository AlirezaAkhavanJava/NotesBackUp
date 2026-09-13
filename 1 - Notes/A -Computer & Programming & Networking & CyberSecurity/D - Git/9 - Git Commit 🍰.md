

# Git Commit — From Basics to Advanced

## 1. What is a Commit? (The Basics)

- A **commit** in Git is like a **snapshot** of your project at a given time.
    
- Every commit:
    
    - Saves the **changes** you made (not the entire repo every time).
        
    - Has a **unique ID (SHA-1 hash)** to identify it.
        
    - Stores:
        
        - The actual changes.
            
        - Metadata (author, date, commit message, parent commit, etc).
            
- Think of it like pressing **save in a video game**: You can always go back to that state.
    

Example:

```bash
git add file.txt
git commit -m "Added file.txt"

#Tip

# Change the last commit message
git commit --amend -m "A: add contents.md"

```

---

## 2. What Does Git Actually Save?

Git doesn’t store diffs like some systems. Instead:

- Each commit creates **objects** in Git’s internal database (`.git/objects`):
    
    - **Blob** → File contents (binary large object).
        
    - **Tree** → Directory structure (points to blobs and other trees).
        
    - **Commit** → Metadata + pointer to a tree + parent commit(s).
        
- That means each commit = snapshot of the entire project (but Git reuses unchanged blobs → efficient storage).
    

Example structure:

```
Commit A → Tree → Blobs (file1, file2, ...)
Commit B → Tree → Blobs (file1 changed, file2 same, ...)
```

---

## 3. How Commits Work (Step by Step)

1. You modify files in the **working directory**.
    
2. You run `git add file` → moves changes to the **staging area (index)**.
    
3. You run `git commit` → Git packages:
    
    - Tree object (snapshot of staging area).
        
    - Commit object (message + metadata + pointer to tree + parent commit).
        
    - SHA-1 hash generated → unique commit ID.
        

---

## 4. Metadata Inside a Commit

Each commit stores:

- **SHA-1 hash (40 chars)** → `d670460b4b4aece5915caf5c68d12f560a9fe3e4`
    
- **Author** (name + email).
    
- **Committer** (can differ from author).
    
- **Date/time**.
    
- **Parent commit(s)** (merge commits can have multiple).
    
- **Pointer to tree object**.
    
- **Message**.
    

You can inspect with:

```bash
git cat-file -p <commit-hash>
```

---

## 5. Commit Graph

- Commits form a **directed acyclic graph (DAG)**.
    
- Each commit points to its parent.
    
- Branches are just **pointers to commits**.
    
- Example:
    

```
A → B → C → D
```

- If you create a new branch at `C` and commit:
    

```
A → B → C → D (main)
           ↘ E (feature)
```

---

## 6. Different Types of Commits

- **Normal commit** → one parent.
    
- **Merge commit** → multiple parents (when merging branches).
    
- **Root commit** → first commit in a repo (no parent).
    
- **Amended commit** → replaces last commit with new one.
    
- **Cherry-pick commit** → copy of another commit applied elsewhere.
    
- **Rebase commit** → rewritten commit with a new parent.
    

---

## 7. Advanced Commit Concepts

### a) Commit Hash Internals

- SHA-1 is computed from commit’s content → guarantees integrity.
    
- If anything changes (file, message, metadata), commit hash changes.
    

### b) Detached HEAD

- Normally HEAD points to the latest commit in a branch.
    
- If you checkout a commit directly:
    
    ```bash
    git checkout <commit-hash>
    ```
    
    → HEAD is “detached” (not on a branch).  
    Useful for testing old states.
    

### c) Amending Commits

- Fix mistakes without creating a new commit:
    
    ```bash
    git commit --amend
    ```
    

### d) Interactive Rebase (Rewriting Commit History)

- Lets you edit, squash, reorder commits.
    
    ```bash
    git rebase -i HEAD~3
    ```
    

### e) Signed Commits

- Commits can be cryptographically signed (GPG/SSH).
    
    ```bash
    git commit -S -m "Signed commit"
    ```
    

### f) Commit Ranges

- `git log A..B` → commits reachable from B but not A.
    
- Useful for code reviews, CI/CD, patches.
    

### g) Object Database Plumbing

- Low-level Git commands:
    
    - `git hash-object` → create blob manually.
        
    - `git cat-file` → inspect objects.
        
    - `git ls-tree` → see tree contents.
        

---

## 8. Best Practices for Commits

- **Atomic commits**: one logical change per commit.
    
- **Descriptive messages**: explain _why_, not just _what_.
    
- **Small commits**: easier to review/revert.
    
- **Use branches**: keep history clean.
    

---

## 9. Visualizing Commits

```bash
git log --oneline --graph --all
```

Shows commit graph like:

```
* d12c3ab (main) Fix bug
* 9fceb02 Add feature
| * 7c9f0d1 (feature) Work in progress
|/
* 5e3ee11 Initial commit
```

---

 In short:

- **Commit = snapshot + metadata + parent link.**
    
- Stored as objects (blobs + trees + commit).
    
- Forms a graph structure.
    
- Can be rewritten, signed, rebased, cherry-picked.
    

---



[[0 - Git 🍋‍🟩]]