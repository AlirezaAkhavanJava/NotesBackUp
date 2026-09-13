
## Blob

A **blob** ("binary large object") stores **only the raw content of a file** — nothing else. No filename, no path, no permissions, no timestamp. Just the bytes.

### Where it's stored

Like every Git object, a blob lives at:

```
.git/objects/<first 2 chars of hash>/<remaining 38 chars>
```

Example: content hashing to `5e1c309dae7f45e0f39b1bf3ac3cd4d0f0f6d4b6` is stored at:

```
.git/objects/5e/1c309dae7f45e0f39b1bf3ac3cd4d0f0f6d4b6
```

This path has **nothing to do with the file's original location** in your project. `src/main/java/App.java` might produce a blob stored at `.git/objects/5e/1c30...` — completely unrelated-looking paths.

### Why no `.java`, `.js`, `.md` extension?

Because **the blob doesn't know or care what file it came from.** It's pure content. The filename, extension, path, and permissions are **metadata about the file's location in the project structure** — and that information is stored separately, in the **tree** object, not the blob.

Think of it this way:

- Blob = "these exact bytes exist somewhere in this repo's history"
- Tree = "this blob is named `App.java` and lives in folder `src/main/java/`"

This separation is _why deduplication works_: if `App.java` and `AppCopy.java` have identical content, they produce the exact same blob hash and are stored **once** — even though they have different names in two different places in the tree.

```bash
git hash-object App.java       # computes the blob hash without even staging it
git cat-file -p <blob-hash>    # shows raw content — no filename info at all
```

---

## Content-Addressed (Storage)

**Content-addressed** means an object's identity (its hash/address) is **derived entirely from its content** — not assigned arbitrarily, not based on location or name.

- Same content → same hash, every time, guaranteed
- Different content, even by one byte → completely different hash
- This makes Git's storage a giant **key-value store**: `hash → content`

Contrast this with a normal filesystem, which is **location-addressed** (a file is identified by its path, like `/home/user/App.java`, regardless of what's inside it).

---

## SHA-1 (Secure Hash Algorithm 1)

SHA-1 is the hashing algorithm Git uses to generate an object's unique 40-character hexadecimal identifier.

### What actually gets hashed

Not just the raw content — Git hashes a formatted header + content:

```
<type> <byte-length>\0<content>
```

Example for a blob containing `"Hello"`:

```
blob 5\0Hello
```

That entire string is run through SHA-1 → produces the hash.

### Why the header matters

It means a blob and a commit could never accidentally collide even with similar content, since the object **type** is baked into what's hashed. It also means Git can verify integrity — if you know the hash, you can independently recompute it from the content and confirm nothing was corrupted or tampered with.

---

## Tree

A **tree** represents a **directory** — a snapshot of what files and subfolders exist, and what each one points to.

Each entry in a tree contains:

|Field|Example|
|---|---|
|File mode|`100644` (regular file), `100755` (executable), `040000` (subdirectory)|
|Type|`blob` or `tree`|
|Hash|pointer to the blob or subtree object|
|Name|`App.java`, `src/`, etc.|

```bash
git ls-tree HEAD
```

Might output:

```
100644 blob 5e1c309d...   App.java
100644 blob 8f2a1e4b...   README.md
040000 tree 3c9d7f21...   src
```

**This is where filenames live.** The tree is the _only_ place that connects a blob's hash to a human-readable filename and location.

A tree can point to:

- Blobs (files)
- Other trees (subdirectories) — this is how nested folder structures are represented recursively

---

## Commit

A **commit** doesn't store files or diffs directly — it stores:

|Field|Meaning|
|---|---|
|**tree**|hash of the _root_ tree — the entire project's structure at this moment|
|**parent(s)**|hash of the previous commit (or multiple, for merges) — omitted entirely for the very first commit|
|**author**|who wrote the change + timestamp|
|**committer**|who applied the commit + timestamp (can differ, e.g. after rebase)|
|**message**|why the change was made|

```bash
git cat-file -p <commit-hash>
```

Might output:

```
tree 3c9d7f21a8e4b5c6...
parent 9f8e7d6c5b4a3210...
author Alireza <email> 1694000000 +0330
committer Alireza <email> 1694000000 +0330

fix: prevent crash on expired token
```

---

## How Git Knows Which Blob Belongs to Which Tree

**Trees explicitly list the mapping.** A tree object is literally a list of entries, each one saying: _"this exact hash (a blob or another tree) is named this, at this path."_

```
tree
 ├── entry: blob 5e1c309d... named "App.java"
 ├── entry: blob 8f2a1e4b... named "README.md"
 └── entry: tree 3c9d7f21... named "src"
```

There's no separate "index of blobs" — the tree _is_ the index. Git walks the tree top-down: root tree → entries → either a blob (done) or another tree (recurse into it).

---

## How Each Tree Is Known by a Commit — and the Role of Parent

The **commit object holds a single field: `tree <hash>`**, pointing to exactly one root tree — the complete project snapshot for that commit.

The **parent field** is what turns a pile of independent snapshots into actual _history_:

```
commit C3  →  tree T3   parent: C2
commit C2  →  tree T2   parent: C1
commit C1  →  tree T1   parent: (none — first commit)
```

- Walking backward through `parent` pointers, commit by commit, **is** what `git log` does to reconstruct history
- A **merge commit** has **two (or more) parents**, representing where two histories joined
- The very first commit in a repo has **no parent** — it's the root

---

## Putting the Whole Chain Together

```
commit (C3)
 ├── parent → commit (C2) → parent → commit (C1) → parent: none
 └── tree (T3)
       ├── blob: App.java content
       ├── blob: README.md content
       └── tree: src/
             └── blob: Helper.java content
```

Every arrow in this diagram is just **a SHA-1 hash pointing to another object**. That's the entire mechanism — no magic, just hashes referencing other hashes, all content-addressed, all immutable.

---

**One-line definitions to remember:**

> **Blob** = raw file content, no name attached. **Tree** = a directory listing that assigns names/paths to blobs and subtrees. **Commit** = a snapshot pointer (to one tree) + a link to history (via parent) + metadata.




[[0 - Git 🍋‍🟩]]