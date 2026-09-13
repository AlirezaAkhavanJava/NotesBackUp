
# Git Object Hashing — A Short Tutorial

## The Core Idea

Git is a **content-addressable** system. Every object is hashed, and the hash is a **pure function of the object's serialized bytes**. Nothing else — not the device, not the repo, not the path — affects the hash.

**Identical contents ⟹ identical hash, everywhere.**
**Different contents ⟹ different hash (with overwhelming probability).**

## The Three Object Types

### Blob — file contents
A blob is just the raw bytes of a file. Its hash depends on **contents only** — no filename, no path, no metadata.

> Two files with the same bytes anywhere in the world share the same blob hash.

### Tree — a directory listing
A tree lists entries. Each entry contains:
- mode (e.g. `100644`, `100755`, `040000`, `120000`)
- type (blob or tree)
- hash of the child object
- filename

So a tree hash depends on the **child hashes plus their names and modes**. Renaming a file changes the tree hash even if the content is unchanged.

### Commit — a snapshot pointer
A commit contains:
- tree hash (root of the snapshot)
- parent commit hash(es)
- author name, email, timestamp, timezone
- committer name, email, timestamp, timezone
- commit message
- (optional) signature

A commit hash depends on **all of these fields**. The timestamp is just one field — not "the basis" of the hash.

## The Merkle DAG

Because each object references others by hash, Git forms a Merkle DAG:

```
commit ──► tree ──► blob
   │         └───► tree ──► blob
   └──► parent commit ──► ...
```

Change any byte anywhere — a file, a filename, a timestamp, a parent — and every hash up the chain changes. This is what makes Git tamper-evident.

## Common Misconceptions

| Claim | Verdict |
|---|---|
| Same blob contents ⟹ same blob hash on any device | ✅ True |
| Same tree entries ⟹ same tree hash on any device | ✅ True |
| Commit hashes are unique per device | ❌ False |
| Two independent commits can never share a hash | ❌ False |

A commit hash **can** be identical across devices. Clone a repo and every commit hash matches. Reproduce the same tree, parent, author, committer, timestamp, and message, and you reproduce the exact commit hash.

## The One Rule to Remember

> **The hash is a pure function of the serialized object bytes.**
> Same bytes → same hash. Always. Everywhere.

That's it. Blobs, trees, and commits are all just objects — the commit isn't special, it's just a bigger structure.


[[0 - Git 🍋‍🟩]]