Date : 2025-08-30

When people think of Git, they imagine "a tool that tracks changes." That’s surface-level. Under the hood, Git is basically a **content-addressable database** with a tiny filesystem of its own.

---

## 🔩 How Git Stores Data

Everything Git does revolves around **objects** stored in the hidden `.git/objects` directory. There are four key object types:

1. **Blob (Binary Large OBject)**
    
    - Stores the _content_ of a file.
        
    - Doesn’t care about filenames or directory structure, just raw data.
        
    - Identified by a **SHA-1 hash** of its contents.
        
    - Example: a text file with `Hello World` would be stored as a blob object with some hash like `6d0fd1...`.
        
2. **Tree**
    
    - Represents a directory (folder).
        
    - Maps filenames to blob hashes (files) or other tree hashes (subdirectories).
        
    - Keeps track of file **names, permissions, and hierarchy**, since blobs only store content.
        
3. **Commit**
    
    - Represents a snapshot of the project at a point in time.
        
    - Points to a **tree** (the root directory at that commit).
        
    - Contains metadata: author, committer, message, parent commit(s).
        
    - Parents connect commits into a history graph (DAG).
        
4. **Tag**
    
    - Just a label (e.g., `v1.0.0`) that points to a commit.
        
    - Useful for releases.
        

---

## ⚙️ The Workflow in Action

1. **You add a file (`file.txt`) and commit it**:
    
    - Git stores the file contents in a **blob object**.
        
    - A **tree object** is created that maps `"file.txt"` → blob hash.
        
    - A **commit object** is created pointing to that tree.
        
    
    Now your repo has 3 objects: 1 blob, 1 tree, 1 commit.
    
2. **You change the file and commit again**:
    
    - New blob (new hash, since contents changed).
        
    - New tree (points to the new blob).
        
    - New commit (points to new tree, parent = old commit).
        
    
    Git doesn’t store diffs—it stores _snapshots_.  
    But it’s smart: if files don’t change, the tree just reuses existing blobs.
    

---

## 📂 Example Object Graph

```
Commit A
  |
  └── Tree (root)
        └── file.txt -> Blob("Hello")
```

Next commit after editing file:

```
Commit B (parent: A)
  |
  └── Tree (root)
        └── file.txt -> Blob("Hello World")
```

---

## 🔑 Key Idea

- Git doesn’t think in "lines changed."
    
- Git thinks in "snapshots of the whole project."
    
- The hashing (SHA-1) ensures integrity: if even one byte changes, the hash changes, so corruption is obvious.
    
- Branches and HEAD are just **pointers (refs)** to commits.
    

---

👉 So, when you run `git add` and `git commit`, you’re literally building a graph of immutable objects: **blobs → trees → commits**, stitched together by hashes.

That’s Git’s "data storage model." Everything else (branches, merges, rebases) is built on top of this foundation.

---

# 🔬 Git Internals — Advanced

## 1. **The Object Database: `.git/objects`**

- Every object is stored as:
    
    `.git/objects/aa/bbcd1234...`
    
    - `aa` = first two hex chars of the SHA-1.
        
    - `bbcd1234...` = remaining chars.
        
- Each object is:
    
    - **Compressed (zlib)**
        
    - **Named by its SHA-1 hash**
        
- Objects are immutable — change content → new hash → new object.
    

---

## 2. **Content-Addressable System**

Git is essentially a **key-value store**:

`git hash-object -w file.txt`

- `hash-object` stores the file as a blob.
    
- It outputs the hash (the "address").
    
- Later you can retrieve with:
    

`git cat-file -p <hash>`

That’s Git’s plumbing: insert data by content, retrieve by hash.

---

## 3. **Packfiles (Optimization)**

Storing each object separately is wasteful. Enter **packfiles**:

- Git periodically runs **garbage collection**:
    
    `git gc`
    
- This compresses objects into a `.pack` file.
    
- Deltas are used:
    
    - Instead of storing full blobs, Git stores _differences_ between similar objects.
        
    - Example: two versions of a source file are stored as "base + delta."
        

This makes repos with thousands of commits stay lightweight.

---

## 4. **Refs: The Naming Layer**

- Commits are just hashes. Impossible to memorize.
    
- **Refs** map human-readable names to hashes:
    
    - `refs/heads/main` → commit hash
        
    - `refs/tags/v1.0` → commit hash
        
- `HEAD` is a special ref pointing to "where you are."
    
- When you `checkout`, Git moves `HEAD` to point to another branch.
    

Branches are _cheap_: just pointers to commits.

---

## 5. **Commit Graph (DAG)**

- Commits form a **Directed Acyclic Graph**.
    
- Each commit points to one or more parents:
    
    - Normal commit: 1 parent.
        
    - Merge commit: 2+ parents.
        
- No cycles: history always flows forward.
    

Example:

`A <- B <- C <- D (main)        \         E <- F (feature)`

`git merge feature` creates:

        `E <- F        /     \ A <- B <- C <- D <- M (merge commit)`

---

## 6. **Rebase vs Merge (Internals)**

- **Merge**: create a new commit with 2 parents. Keeps full history.
    
- **Rebase**: replays commits on top of another branch. Creates _new_ commits with new hashes (rewriting history).
    

Why? Commits are immutable — you can’t "move" them, only copy them.

---

## 7. **Index (Staging Area)**

- Lives in `.git/index`.
    
- It’s a binary file that tracks what will go into the next commit.
    
- Contains:
    
    - Pathname
        
    - Blob hash
        
    - Mode (permissions)
        
    - File metadata
        
- When you `git add`, you update the index.
    
- When you `git commit`, Git writes index → tree → commit.
    

---

## 8. **Plumbing vs Porcelain**

- **Plumbing**: low-level commands (`hash-object`, `cat-file`, `update-ref`) — the raw internals.
    
- **Porcelain**: user-facing commands (`add`, `commit`, `merge`) — the nice UX.
    

Git was originally designed as plumbing. Porcelain came later.

---

## 9. **Integrity & Security**

- SHA-1 hash ensures:
    
    - Content cannot be silently corrupted.
        
    - If a single byte changes, hash changes → commit chain breaks.
        
- Git is _content-trustworthy_ by design.
    

---

## 10. **Distributed Nature**

- Every clone has the full object database (commits, blobs, trees).
    
- That’s why you can work offline — no central server required.
    
- Remotes are just _another repo_ with refs you sync against.
    

---

## 🧠 Mental Model

Git is a:

- **Key-value database** (objects by SHA-1)
    
- **Filesystem snapshot system** (trees)
    
- **History graph** (commits as nodes in a DAG)
    
- **Ref manager** (branches/tags = pointers)
    
- **Compression engine** (packfiles)
    

Everything else is an illusion built on top.


##### *Tags : [[0 - Git 🍋‍🟩]]