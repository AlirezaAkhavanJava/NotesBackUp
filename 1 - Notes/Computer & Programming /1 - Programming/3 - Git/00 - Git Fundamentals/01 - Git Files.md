

## What "Git files" means

When people say "Git files," they usually mean two different things: the files in your **working tree** (your actual project — source code, configs) and the files Git keeps in `.git/` to track everything about your project's history. The second group is the real subject — Git's own internal database, invisible unless you go looking, and understanding it is what makes commands like `add`, `commit`, `branch`, and `reset` stop feeling like magic.

```
your project files  +  .git/  =  a Git repository
```

Everything below lives inside `.git/`, except for a handful of files (`.gitignore`, `.gitattributes`, `.gitmodules`) that sit next to your project but still configure how Git behaves.

## HEAD

`HEAD` answers one question: "what am I currently on?"

```bash
cat .git/HEAD
```

Normally:

```
ref: refs/heads/main
```

That's a pointer to a pointer — `HEAD` points to a branch name, and the branch name points to a commit. If you check out a specific commit instead of a branch, `HEAD` stores the commit hash directly instead of a `ref:` line. That's **detached HEAD** — any commit you make there won't belong to a branch unless you create one.

## The index (`.git/index`)

The index is the **staging area** — a binary file, not something you read directly. `git add` writes into it; `git commit` reads from it.

```
working tree  →  (git add)  →  index  →  (git commit)  →  repository
```

Inspect what's actually staged with:

```bash
git ls-files --stage
```

```
100644 a1b2c3d... 0  README.md
100755 e4f5g6h... 0  script.sh
160000 f7g8h9i... 0  submodule
```

Each line is `<permissions> <blob hash> <stage number> <path>`. Permission codes: `100644` normal file, `100755` executable, `160000` submodule reference. Stage is `0` on a clean index; during a merge conflict you'll see `1` (common ancestor), `2` (your side), `3` (their side) for the same path until resolved.

## `.git/objects/` — the object database

This is where Git actually stores content. Every object is addressed by the SHA hash of its contents, and there are only four kinds.

|Object|Stores|
|---|---|
|Blob|Raw file contents|
|Tree|A directory listing (names + modes + hashes)|
|Commit|Snapshot metadata: tree, parent, author, message|
|Tag|An annotated tag's metadata|

**Blob** — content only, no filename:

```bash
echo "Hello World" | git hash-object -w --stdin
# 557db03...
git cat-file -p 557db03
# Hello World
```

A blob has no idea what file it belongs to — the filename only exists one layer up, in a tree.

**Tree** — maps names to blobs (files) or other trees (subdirectories):

```bash
git cat-file -p main^{tree}
```

```
100644 blob a1b2c3d...   README.md
040000 tree e4f5g6h...   src
100755 blob i7j8k9l...   script.sh
```

**Commit** — points to one tree (the snapshot) and zero or more parent commits:

```bash
git cat-file -p HEAD
```

```
tree 92b8b6a...
parent a1b2c3d...
author Alireza <...> 1671123400 -0500
committer Alireza <...> 1671123400 -0500

Add authentication
```

A commit never stores files directly — it points to a tree, the tree points to blobs and sub-trees. Every commit is really just "a tree, plus a pointer to the commit before it."

Physically, objects start as loose files under `.git/objects/<first 2 hex chars>/<remaining 38 chars>`, but Git periodically compresses many loose objects into a single `pack-*.pack` file (with a matching `.idx`) for space and speed — that's what `git gc` does.

## `.git/refs/` — named pointers to commits

A ref is nothing more than a file holding a commit hash.

```
.git/refs/
├── heads/      local branches
├── remotes/    remote-tracking branches
└── tags/       tags
```

```bash
cat .git/refs/heads/main
# a91fd21...
```

- **`refs/heads/`** — local branches. `main` pointing at `a91fd21` just means "the tip of `main` is `a91fd21`."
- **`refs/remotes/`** — remote-tracking branches like `refs/remotes/origin/main`. `origin` is just the name you gave the remote; `origin/main` is Git's local _memory_ of where that remote's `main` was, last time you fetched. It updates only on `fetch`/`pull`/`push`, never automatically.
- **`refs/tags/`** — lightweight tags are just a hash; annotated tags point to an actual tag object with its own metadata:

```bash
git cat-file -p v1.0.0
```

```
object 92b8b6a...
type commit
tag v1.0.0
tagger John Doe <...>

Release version 1.0.0
```

For repos with lots of refs, Git can collapse them into one `.git/packed-refs` file instead of hundreds of tiny files — so if `cat .git/refs/tags/v1.0` comes up empty, check `packed-refs` before assuming the tag is gone.

## `.git/config`

Repository-local settings, overriding your global `~/.gitconfig`:

```ini
[core]
    repositoryformatversion = 0
    filemode = true
[remote "origin"]
    url = https://github.com/example/project.git
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
    remote = origin
    merge = refs/heads/main
```

The `[branch "main"]` block is what makes plain `git pull`/`git push` on `main` know which remote and remote-branch to talk to without you specifying it each time.

## `.git/logs/` — reflogs

Every time a ref moves (commit, checkout, reset, rebase...), Git appends a line to a reflog. This is your safety net — local only, never pushed, and it expires after a while.

```bash
git reflog
```

```
a91fd21 HEAD@{0}: commit: Add API
72de123 HEAD@{1}: checkout: moving from dev to main
```

This is what lets you recover a commit after a `git reset --hard` you regret — the commit object is still sitting in `.git/objects/`, and the reflog still remembers its hash even though no branch points to it anymore.

## `.git/hooks/`

Scripts Git runs automatically at specific points — `pre-commit`, `commit-msg`, `pre-push`, `post-checkout`, and others. Git ships each as a `<name>.sample` file; you activate it by removing `.sample` and making it executable.

```bash
#!/bin/bash
# .git/hooks/pre-commit
npm test || { echo "Tests failed! Commit aborted."; exit 1; }
```

Hooks are **local only** — they live in `.git/`, which isn't tracked or pushed, so they don't travel with the repo unless you manage them separately.

## Files outside `.git/` that still configure Git

These live in your project root, get committed, and travel with the repo — unlike hooks.

- **`.gitignore`** — patterns for untracked files to skip. Key gotcha: it has **no effect on files Git already tracks** — removing a tracked file from `.gitignore` won't untrack it; you need `git rm --cached` for that.
- **`.gitattributes`** — per-path behavior: line-ending normalization, marking files as binary (so Git won't try to diff/merge them), custom diff/merge drivers:
    
    ```
    *.sh text eol=lf
    *.png binary
    package-lock.json binary
    ```
    
- **`.gitmodules`** — tracks submodules (repos nested inside your repo):
    
    ```ini
    [submodule "library"]
        path = library
        url = https://github.com/example/library.git
    ```
    
- **`.gitkeep`** — not a real Git feature, just a convention. Git never tracks empty directories, so people drop an empty `.gitkeep` file in one to force it to exist in the repo.
- **`info/exclude`** (inside `.git/`, worth knowing alongside `.gitignore`) — same job as `.gitignore`, but local-only and never committed. Good for personal IDE junk you don't want to impose on teammates.

## Putting it together

```
project/
├── .gitignore / .gitattributes / .gitmodules   ← tracked, shape Git's behavior
└── .git/
    ├── HEAD        → current branch/commit pointer
    ├── config      → repo-local settings
    ├── index       → staging area
    ├── objects/    → blobs, trees, commits, tags (the actual database)
    ├── refs/       → heads/, remotes/, tags/
    ├── logs/       → reflogs (local safety net)
    └── hooks/      → local automation scripts
```

And the core chain everything above exists to support:

```
working tree → index → commit → tree → blob
                  ↑        ↓
                  └── parent commit
```

Every porcelain command you already know — `add`, `commit`, `branch`, `checkout`, `reset`, `merge` — is really just a controlled way of moving data through this chain.



[[Git & Github]]