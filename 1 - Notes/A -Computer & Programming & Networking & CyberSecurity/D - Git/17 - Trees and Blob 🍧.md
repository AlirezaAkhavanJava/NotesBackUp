Date : 2025-08-30


In Git, both **trees** and **blobs** are _objects_ stored in the repository’s object database (`.git/objects`).

### 1. **Blob (Binary Large Object)**

- A **blob** represents **file contents only**.
    
- It does not store filenames, permissions, or directory structure.
    
- Each unique file content (even if used in multiple places) is stored once, keyed by its SHA-1/SHA-256 hash.
    
- Example: If you have a file `hello.txt` with text `"Hello"`, Git will create a blob object for that content.
    

Think of a blob as:

```
"Here’s the exact content of a file."
```

---

### 2. **Tree**

- A **tree** represents a **directory**.
    
- It stores:
    
    - references (hashes) to blobs (files) and other trees (subdirectories)
        
    - filenames
        
    - file modes (permissions, executable bit, symlink, etc.)
        

So a tree ties filenames to blob objects (contents).  
It’s basically a directory listing:

Example tree structure:

```
tree (root)
 ├── blob: (hash of hello.txt content) "hello.txt"
 └── tree: (hash of subdir)
         └── blob: (hash of world.txt content) "world.txt"
```

---

### 3. **Relationship**

- **Blob** = raw file data.
    
- **Tree** = snapshot of directory (maps names → blobs/trees).
    
- A **commit** then points to a tree (the root directory snapshot) + metadata (author, message, parents).
    

So Git history is a graph of commits → trees → blobs.

---

**essential Git commands** to inspect **trees** and **blobs**:

### 1. Show a commit’s tree

```bash
git ls-tree HEAD
```

Lists files (blobs) and subdirectories (trees) in the commit pointed to by `HEAD`.

---

### 2. Show a tree inside a directory

```bash
git ls-tree HEAD:path/to/dir
```

Shows contents of a subdirectory (tree object).

---

### 3. Show raw tree object

```bash
git cat-file -p <tree_hash>
```

Reveals filenames, modes, and object hashes inside that tree.

---

### 4. Show a blob (file content)

```bash
git cat-file -p <blob_hash>
```

Prints the file content stored in a blob object.

---

### 5. Find object type

```bash
git cat-file -t <hash>
```

Tells you if it’s a **blob**, **tree**, or **commit**.

---

### 6. Explore objects in `.git/objects/`

```bash
git rev-parse HEAD       # get latest commit hash
git cat-file -p <commit_hash>   # see tree hash
git cat-file -p <tree_hash>     # see blobs/trees inside
```

---

##### *Tags : [[0 - Git 🍋‍🟩]]