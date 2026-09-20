
When we talk about **Git files**, we usually mean the files Git uses to store your project history, configuration, references, and internal database.

The key distinction is:

```text
Your project files
        +
      .git/
        ↓
   Git repository
```

# 1. `.git/` — the Git database

When you run:

```bash
git init
```

Git creates:

```text
.git/
```

This directory is the **Git repository's internal data store**.

It contains things like:

```text
.git/
├── HEAD
├── config
├── index
├── objects/
├── refs/
├── logs/
├── hooks/
└── ...
```

The important ones are:

|File / directory|Definition|
|---|---|
|`.git/HEAD`|Tells Git what `HEAD` currently refers to|
|`.git/config`|Repository-specific Git configuration|
|`.git/index`|The staging area|
|`.git/objects/`|Stores Git objects: commits, trees, blobs, tags|
|`.git/refs/`|Stores references such as branches and tags|
|`.git/logs/`|Stores reflogs|
|`.git/hooks/`|Client/server hook scripts|
|`.git/packed-refs`|Packed representation of references|

---

# 2. `.git/HEAD`

You were just looking at this concept.

Check it:

```bash
cat .git/HEAD
```

Typical result:

```text
ref: refs/heads/main
```

This means:

```text
HEAD
 ↓
refs/heads/main
 ↓
<commit hash>
```

So `HEAD` normally points to your **current branch**, not directly to a commit.

---

# 3. `.git/refs/`

This stores Git's **references**.

You saw this:

```text
.git/refs/
├── heads/
├── remotes/
└── tags/
```

### `refs/heads/`

Contains local branches.

Example:

```text
.git/refs/heads/main
.git/refs/heads/dev
```

Inside `main`:

```bash
cat .git/refs/heads/main
```

might give:

```text
a91fd21...
```

That hash is the commit that `main` currently points to.

So:

```text
main
 ↓
commit
```

---

### `refs/remotes/`

Contains **remote-tracking branches**.

For example:

```text
.git/refs/remotes/origin/main
```

This represents:

```text
origin/main
```

Important:

> `origin` is the remote's name.  
> `origin/main` is a remote-tracking branch.

---

### `refs/tags/`

Contains tag references.

For example:

```text
.git/refs/tags/v1.0
```

---

# 4. `.git/index`

This is one of Git's most important files.

It represents the **staging area**.

When you do:

```bash
git add User.java
```

Git puts information about the staged version into:

```text
.git/index
```

The conceptual flow is:

```text
Working tree
     │
     │ git add
     ▼
  Index
     │
     │ git commit
     ▼
 Repository
```

So:

```text
Working tree → Index → Commit
```

---

# 5. `.git/objects/`

This is Git's **object database**.

Git primarily stores four kinds of objects:

|Object|Stores|
|---|---|
|Blob|File contents|
|Tree|Directory structure|
|Commit|Snapshot metadata + parent relationship|
|Tag|Annotated tag information|

You can inspect it:

```bash
find .git/objects
```

You'll see directories such as:

```text
.git/objects/12/
.git/objects/a9/
.git/objects/f3/
```

Git identifies objects using SHA-1 or SHA-256 depending on repository configuration.

Conceptually:

```text
Commit
  │
  └── Tree
       ├── Blob → User.java
       ├── Blob → UserService.java
       └── Tree → repository/
```

---

# 6. Blob

A **blob** stores file content.

For example:

```text
User.java
```

might have content:

```java
public class User {
    String name;
}
```

Git stores that content as a blob.

Important:

> A blob does **not** store the filename.

The filename is associated with the blob through a **tree**.

---

# 7. Tree

A **tree** represents a directory/snapshot structure.

Conceptually:

```text
Tree
├── User.java      → blob
├── UserService.java → blob
└── repository/    → tree
```

So:

```text
Tree = directory structure
Blob = file content
```

---

# 8. Commit object

A commit stores metadata about a snapshot.

Conceptually:

```text
Commit
├── tree <tree-hash>
├── parent <previous-commit>
├── author
├── committer
└── message
```

For example:

```text
commit a91fd21
tree 82bc...
parent 72de...
author Alireza ...
committer Alireza ...

Add authentication
```

The commit points to a tree, and the tree points to blobs/other trees.

---

# 9. `.git/config`

Repository-specific configuration.

View it:

```bash
cat .git/config
```

Example:

```ini
[core]
    repositoryformatversion = 0
    filemode = true

[remote "origin"]
    url = https://github.com/example/project.git
    fetch = +refs/heads/*:refs/remotes/origin/*
```

This is where Git can store information such as the `origin` remote.

---

# 10. `.git/logs/`

Contains **reflogs**.

Important files:

```text
.git/logs/HEAD
.git/logs/refs/heads/main
```

These record movements of refs.

For example:

```bash
git reflog
```

may show:

```text
a91fd21 HEAD@{0}: commit: Add API
72de123 HEAD@{1}: checkout: moving from dev to main
```

This is especially useful when you accidentally reset, rebase, or delete something.

---

# 11. `.git/hooks/`

Contains hook scripts.

Examples:

```text
.git/hooks/
├── pre-commit
├── commit-msg
├── pre-push
└── post-update
```

Hooks allow Git to automatically execute scripts at particular operations.

For example:

```text
git commit
    ↓
pre-commit hook
    ↓
commit created
```

---

# 12. `.gitignore`

This is **not inside `.git/`**.

It is normally in your project root:

```text
project/
├── .git/
├── .gitignore
├── src/
└── pom.xml
```

It tells Git which **untracked files should be ignored**.

Example:

```gitignore
target/
.idea/
*.log
.env
```

Important distinction:

`.gitignore` does **not** remove files that Git is already tracking.

---

# 13. `.gitattributes`

Another normal repository file:

```text
.gitattributes
```

Controls Git's handling of paths, such as:

```text
*.sh text eol=lf
*.jpg binary
```

It can influence:

- line endings
    
- diff behavior
    
- merge behavior
    
- attributes of specific files
    

---

# 14. `.gitmodules`

Used when your repository contains Git submodules.

Example:

```text
.gitmodules
```

may contain:

```ini
[submodule "library"]
    path = library
    url = https://github.com/example/library.git
```

---

# 15. `packed-refs`

Sometimes Git doesn't store refs as individual files.

Instead you may find:

```text
.git/packed-refs
```

Example:

```text
a91fd21... refs/tags/v1.0
82bc123... refs/remotes/origin/main
```

Git can **pack references** for efficiency.

So you might not always see:

```text
.git/refs/tags/v1.0
```

because the ref may have been packed.

---

# 16. Your complete mental model

Think of a Git repository like this:

```text
project/
│
├── source files              ← your working tree
│
├── .gitignore                ← ignore rules
├── .gitattributes            ← path attributes
├── .gitmodules               ← submodules
│
└── .git/                     ← Git's database
    │
    ├── HEAD                  ← current HEAD
    ├── config                ← repository configuration
    ├── index                 ← staging area
    │
    ├── objects/              ← Git objects
    │   ├── blobs
    │   ├── trees
    │   └── commits
    │
    ├── refs/
    │   ├── heads/            ← local branches
    │   ├── remotes/          ← remote-tracking branches
    │   └── tags/             ← tags
    │
    ├── logs/                 ← reflogs
    └── hooks/                ← Git hooks
```

And the **core architecture** is:

```text
                         ┌── refs/heads/main
                         │
Working Tree → Index → Commit → Tree → Blob
                         │
                         └── Parent Commit
```

This is the foundation for understanding why:

```bash
git add
git commit
git branch
git checkout
git switch
git reset
git merge
git log
```

all behave the way they do.


[[0 - Git 🍋‍🟩]]