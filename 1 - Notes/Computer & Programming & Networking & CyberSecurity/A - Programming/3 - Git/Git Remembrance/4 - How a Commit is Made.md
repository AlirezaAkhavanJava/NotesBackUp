

### The Commands (User-Facing Workflow)

```bash
git add <file>          # stage changes (working dir → index)
git add -p               # stage selectively, chunk by chunk
git add .                 # stage everything
git commit -m "message"   # create the commit
git commit --amend        # modify the last commit instead of creating a new one
git commit -a -m "msg"    # skip staging, commit all tracked file changes directly
```

---

## What Happens Internally When You Commit

Let's say you edit `app.js` and run `git add app.js` then `git commit -m "fix bug"`.

### Step 1 — `git add` (Staging)

- Git reads the file content
- Compresses it (zlib) and computes its **SHA-1 hash**
- Stores it as a **blob object** in `.git/objects/`
- Updates the **index** file to say: "`app.js` now points to this new blob"

At this point, nothing in `.git`'s history has changed yet — only the index and the object database gained a new blob.

### Step 2 — `git commit`

1. Git looks at the current **index** (what's staged)
2. Builds a **tree object** representing the full directory structure — for every folder, a tree; for every file, a pointer to its blob
3. Creates a **commit object** containing:
    - Pointer to the root tree (the snapshot)
    - Pointer(s) to parent commit(s)
    - Author name/email + timestamp
    - Committer name/email + timestamp (can differ from author, e.g. after a rebase)
    - Commit message
4. This commit object is hashed and stored as a new object
5. The current branch ref (e.g. `.git/refs/heads/main`) is updated to point to this new commit hash
6. `HEAD` still points to the branch name, so it now "follows" to the new commit automatically

```
commit_object
 ├── tree: a1b2c3...        (root snapshot)
 ├── parent: 9f8e7d...       (previous commit)
 ├── author: Alireza <...>  timestamp
 ├── committer: Alireza <...> timestamp
 └── message: "fix bug"
```

---

## How the SHA-1 Hash is Generated

Git doesn't hash just the raw content — it hashes a **specific formatted string**:

```
<object_type> <content_length>\0<content>
```

For example, a blob's hash is computed from:

```
blob 15\0Hello, World!
```

This whole string is run through SHA-1, producing a 40-character hex hash like:

```
5e1c309dae7f45e0f39b1bf3ac3cd4d0f0f6d4b6
```

**Why this matters:**

- The hash depends on the _content itself_ — same content = same hash, always. This is called **content-addressable storage**.
- If even one byte changes, the hash changes completely.
- Two identical files (even in different folders) produce the **same blob**, stored only once — automatic deduplication.
- A commit's hash also depends on its parent's hash, which depends on _its_ parent, and so on — this creates a tamper-evident chain. Changing any past commit changes its hash, which breaks every hash after it. That's why Git history is so hard to secretly falsify.

_(Note: newer Git versions support SHA-256 as an opt-in alternative, since SHA-1 has known theoretical weaknesses, but SHA-1 is still the default almost everywhere.)_

---

## Where It's All Stored

Everything lives under `.git/objects/`. Each object is stored in a subfolder named by the **first 2 characters** of its hash, with the remaining 38 characters as the filename:

```
.git/objects/5e/1c309dae7f45e0f39b1bf3ac3cd4d0f0f6d4b6
```

You can inspect these directly:

```bash
git cat-file -p 5e1c309d...     # view the content of an object
git cat-file -t 5e1c309d...     # view the object's type (blob/tree/commit)
git ls-tree HEAD                # view the tree of the current commit
git log --oneline               # see commit hashes
```

---

## "Doesn't `.git` end up bigger than the project itself?"

Great instinct to question — and no, it usually doesn't, for several reasons:

### 1. Deduplication

If a file doesn't change between commits, Git does **not** store it again. The new commit's tree just points to the _same existing blob_. Only genuinely new/changed content creates new objects.

### 2. Compression

Every object is zlib-compressed before being written to disk. Text-heavy source code compresses very well (often 60-80% smaller).

### 3. Delta Compression via Packfiles

Loose objects (one file per object) are inefficient at scale, so Git periodically runs **`git gc`** (garbage collection) which:

- Bundles many objects into a single **packfile**
- Finds similar objects (e.g. two versions of the same file) and stores only the **delta** (difference) between them, rather than both full copies
- This is extremely space-efficient for source code history, where most commits change only a small part of a file

```bash
git gc                   # manually trigger optimization
git count-objects -v     # see how many loose objects exist and total size
```

### 4. What Actually Makes `.git` Grow Large

`.git` _can_ balloon past the working directory's size when:

- The project has **very long history** (years of commits)
- **Large binary files** (images, videos, compiled binaries) are committed repeatedly — binaries don't delta-compress well since small changes can scramble the whole file
- History was never cleaned/pruned

This is exactly why tools like **Git LFS (Large File Storage)** exist — to keep large binaries _out_ of the core object database.

---

**Rule of thumb:**

> For a typical text-based codebase, `.git` stays roughly comparable to or smaller than the working directory, thanks to compression and delta-encoding — even though it holds the _entire history_. The moment binary files enter the picture regularly, that assumption breaks down fast.



[[0 - Git 🍋‍🟩]]