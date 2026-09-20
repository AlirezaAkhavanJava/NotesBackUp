
## Git Repository Internals

This is where Git stops feeling like magic. Everything Git does is built on a small set of simple ideas stored inside the `.git` folder.

---

## 1. The `.git` Folder Structure

When you run `git init`, Git creates this structure:

```
.git/
├── HEAD          → pointer to your current branch
├── config        → repo-specific settings
├── description   → used by some tools (rarely relevant)
├── index         → the staging area
├── objects/      → the actual database of all content
├── refs/
│   ├── heads/    → your local branches
│   └── tags/     → your tags
└── logs/         → history of where HEAD/branches have pointed (reflog)
```

---

## 2. The Object Database — Git's Core

Git stores **everything** as objects inside `.git/objects/`. Every object is identified by a **SHA-1 hash** of its content (this is what those 40-character commit IDs are).

There are 4 object types:

|Object|What it stores|
|---|---|
|**Blob**|The raw content of a single file (no filename, no metadata — just data)|
|**Tree**|A snapshot of a directory — maps filenames to blobs (or other trees for subfolders)|
|**Commit**|A pointer to one tree (the project snapshot), plus author, message, timestamp, and pointer(s) to parent commit(s)|
|**Tag**|A named, permanent pointer to a specific commit (used for releases like `v1.0`)|

**Key insight:** A commit doesn't store a "diff." It points to a full tree (snapshot) of the entire project at that moment. Git is smart about storage internally (compression, delta encoding in packfiles), but conceptually, **every commit = a full snapshot**.

```
commit → tree → blobs (files) + trees (subfolders)
```

---

## 3. Refs — Human-Readable Pointers

Raw SHA hashes are hard to work with, so Git uses **refs** (references) as friendly names pointing to commits:

|Ref type|Location|Example|
|---|---|---|
|Branch|`.git/refs/heads/`|`main` → points to the latest commit on that branch|
|Tag|`.git/refs/tags/`|`v1.0` → points to a specific commit|
|Remote-tracking branch|`.git/refs/remotes/`|`origin/main` → last known state of the remote branch|

**A branch is just a file containing a single commit hash.** That's why creating a branch in Git is instant — it's not copying files, it's writing one line to a text file.

---

## 4. HEAD — "Where Am I?"

`HEAD` is a pointer to **whatever branch (or commit) you currently have checked out**.

- Normally: `HEAD` → points to a branch (e.g., `refs/heads/main`) → which points to a commit
- **Detached HEAD**: `HEAD` points directly to a commit instead of a branch (happens when you checkout a specific commit hash or tag)

---

## 5. The Index (Staging Area)

The `index` file is a binary file that represents **what will go into your next commit**. When you run `git add`, you're not touching the working directory or the repository — you're updating this index file.

This is why Git has **three states** for any file's content:

```
Working Directory → (git add) → Staging Area/Index → (git commit) → Repository (.git)
```

---

## 6. Packfiles — Storage Optimization

Loose objects (one file per blob/tree/commit) are inefficient at scale. Periodically (or via `git gc`), Git compresses many objects into a single **packfile**, using delta compression (storing only the _differences_ between similar objects) to save massive space — especially useful for repos with long histories.

---

## Putting It All Together

When you run `git commit`:

1. Git looks at the **index** (staged changes)
2. Creates **blob objects** for any new/changed file content
3. Creates **tree objects** representing the directory structure
4. Creates a **commit object** pointing to the root tree + parent commit(s) + metadata
5. Moves the current **branch ref** to point at this new commit
6. **HEAD** still points to the branch, so it now "sees" the new commit

---

**One-line mental model:**

> Git is a content-addressable database of snapshots (objects), with branches and tags as lightweight pointers into that history, and HEAD marking where you currently are.




[[0 - Git 🍋‍🟩]]