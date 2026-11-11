
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

example : 

```bash
ethan@debian:/mnt/hdd/Home/Programming Files/Git/brandNew$ xxd .git/index       
00000000: 4449 5243 0000 0002 0000 0003 6add dd63  DIRC........j..c 
00000010: 2889 63a1 6add dd63 2889 63a1 0000 0801  (.c.j..c(.c.....   
00000020: 005a 2355 0000 81a4 0000 03e8 0000 03e8  .Z#U............  
00000030: 0000 0019 ea22 c30b a63f 9054 c7e7 fff5  ....."...?.T....  
00000040: 3133 c18a 6360 5ab2 0008 6372 6564 2e74  13..c`Z...cred.t   
00000050: 7874 0000 6add d564 2f36 2786 6add d564  xt..j..d/6'.j..d  
00000060: 2f36 2786 0000 0801 005a 233c 0000 81a4  /6'......Z#<....   
00000070: 0000 03e8 0000 03e8 0000 0025 1942 b06e  ...........%.B.n        
00000080: 4b78 a211 5a5a fd62 de95 55c9 23b0 db02  Kx..ZZ.b..U.#...      
00000090: 0006 6769 742e 6d64 0000 0000 6add dea7  ..git.md....j...
000000a0: 324f dd84 6add dea7 2fb0 7a84 0000 0801  2O..j.../.z.....     
000000b0: 005a 234c 0000 81a4 0000 03e8 0000 03e8  .Z#L............    
000000c0: 0000 0101 e291 44d7 88ce 7449 d4d0 b54b  ......D...tI...K    
000000d0: e8ee e20d 8483 3b0a 0012 6973 5472 6565  ......;...isTree      
000000e0: 2f63 6f6e 7465 6e74 732e 6d64 0000 0000  /contents.md....     
000000f0: 0000 0000 5452 4545 0000 0012 002d 3120  ....TREE.....-1 
00000100: 310a 6973 5472 6565 002d 3120 300a 1cc4  1.isTree.-1 0...    
00000110: e388 b4a8 eefd bef9 cdc9 37fa 6486 8365  ..........7.d..e    
00000120: fe58                      .X                 
ethan@debian:/mnt/hdd/Home/Programming Files/Git/brandNew$
```

by decoding it we get : 

##### Header : 
```bash 
Signature:       DIRC
Version:         2
Tracked files:   3
File size:       290 bytes
```

##### Stored file entries

```bash
File 1:
  Name:          cred.txt
  Size:          25 bytes
  Permissions:   100644
  Owner UID:     1000
  SHA-1:         ea22c30ba63f9054c7e7fff53133c18a63605ab2

File 2:
  Name:          git.md
  Size:          37 bytes
  Permissions:   100644
  Owner UID:     1000
  SHA-1:         1942b06e4b78a2115a5afd62de9555c923b0db02

File 3:
  Name:          isTree/contents.md
  Size:          257 bytes
  Permissions:   100644
  Owner UID:     1000
  SHA-1:         e29144d788ce7449d4d0b54be8eee20d84833b0a
```

##### Additional data
```sh
Extension:       TREE (cached tree)
Index checksum:  1cc4e388b4a8eefdbef9cdc937fa64868365fe58
Checksum valid:  YES
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




[[00 - Git]]