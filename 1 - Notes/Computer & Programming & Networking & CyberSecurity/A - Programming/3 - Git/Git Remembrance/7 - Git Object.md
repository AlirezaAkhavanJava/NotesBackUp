


A **Git object** is the fundamental unit of storage in Git. Every single piece of data Git tracks — file contents, directory structures, commits, tags — is stored as an object inside `.git/objects/`, identified by the **SHA-1 hash** of its content.

> **Mental model:** Git isn't really a "file tracker" — under the hood, it's a simple **key-value database**, where the key is a SHA-1 hash and the value is some compressed content. Everything else (branches, commits, history) is just structure built on top of that.

---

## Core Properties of Every Object

|Property|Meaning|
|---|---|
|**Immutable**|Once created, an object's content never changes. Any change creates a brand-new object with a new hash|
|**Content-addressed**|The object's name (hash) _is_ derived from its content — identical content always produces the identical hash|
|**Compressed**|Stored using zlib compression on disk|
|**Deduplicated automatically**|If two files (or two commits) have identical content, they're stored as the _same_ object, only once|

---

## The 4 Types of Git Objects

|Object|Stores|Analogy|
|---|---|---|
|**Blob**|Raw file content only — no filename, no permissions, no path|The _contents_ of a file|
|**Tree**|A directory listing — maps names → blobs (files) or other trees (subfolders), plus file modes|A _folder_|
|**Commit**|A pointer to one root tree, parent commit(s), author/committer info, timestamp, message|A _snapshot + metadata_|
|**Tag (annotated)**|A pointer to a commit, plus tagger info, message, optional GPG signature|A _labeled bookmark_|

_(Note: a lightweight tag isn't a real object — it's just a ref pointing directly at a commit.)_

---

## How They Relate

```
commit
 └── tree (root of project)
      ├── blob (file1.js)
      ├── blob (file2.md)
      └── tree (subfolder/)
            └── blob (file3.py)
```

A commit never stores diffs — it points to a tree, which is a full snapshot of the entire project structure at that moment, built from blobs and nested trees.

---

## Inspecting Objects Directly

```bash
git cat-file -t <hash>     # show the object's type (blob/tree/commit/tag)
git cat-file -p <hash>     # pretty-print the object's content
git hash-object <file>     # compute what a file's blob hash would be
git ls-tree <hash>         # list a tree object's contents
```

---

## Where They're Stored

```
.git/objects/<first 2 chars of hash>/<remaining 38 chars>
```

Example: hash `5e1c309dae7f45e0f39b1bf3ac3cd4d0f0f6d4b6` is stored at:

```
.git/objects/5e/1c309dae7f45e0f39b1bf3ac3cd4d0f0f6d4b6
```

Later, `git gc` bundles many loose objects into compressed **packfiles** for efficiency (covered earlier).

---

**One-line definition to remember:**

> A Git object is an immutable, SHA-1-addressed unit of data (blob, tree, commit, or tag) that forms the building block of Git's entire storage and history model.




[[0 - Git 🍋‍🟩]]