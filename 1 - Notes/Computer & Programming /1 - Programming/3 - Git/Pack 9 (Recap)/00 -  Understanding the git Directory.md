


## 1. The problem it solves

Imagine Git had to remember every commit, every branch, every file version, and every change you staged.

Where would it store all that information?

**Inside** `**.git/**`**.**

When you run:

```
git init
```

Git creates a `.git/` directory and initializes its internal repository structure.

## 2. Understanding each file and directory

|Name|Type|Purpose|
|---|---|---|
|`objects/`|Directory|Stores Git objects: commits, trees, blobs, and annotated tags|
|`refs/`|Directory|Stores references to commits, including branches and tags|
|`HEAD`|File|Identifies your current branch or commit|
|`index`|File|Represents the staging area|
|`config`|File|Repository-specific Git configuration|
|`hooks/`|Directory|Contains scripts triggered by Git operations|
|`logs/`|Directory|Stores reflogs recording reference movements|
|`info/`|Directory|Contains additional repository information|
|`description`|File|Description used by tools such as Gitweb|
|`branches/`|Directory|Legacy directory for obsolete branch-related mechanisms|
|`COMMIT_EDITMSG`|File|Contains the message from the most recent commit-message editing operation|
|`MERGE_RR`|File|Records conflicts being tracked by Git's reuse recorded resolution mechanism|
|`rr-cache/`|Directory|Stores recorded conflict resolutions for possible reuse|

## 3. The most important ones

### `objects/` — Git's object database

This is where Git stores the actual historical content of your repository.

Git has four main object types:

- **Blob:** Stores file contents.
    
- **Tree:** Stores directory structure and references to blobs and other trees.
    
- **Commit:** Stores a tree reference, parent commit references, author information, and a message.
    
- **Tag:** An annotated tag object containing metadata and a reference to another object.
    

Inspect a commit:

```
git cat-file -p HEAD
```

Inspect its object type:

```
git cat-file -t HEAD
```

### `refs/` — References to commits

Instead of remembering long commit hashes, Git uses readable names.

For example:

```
.git/
└── refs/
    ├── heads/
    │   └── main
    ├── tags/
    └── remotes/
```

`refs/heads/main` represents your local `main` branch.

Its content, when stored as a loose reference, is simply a commit hash.

Note that Git can also store references in packed form instead of individual files.

### `HEAD` — Your current position

Run:

```
cat .git/HEAD
```

You might see:

```
ref: refs/heads/main
```

This means `HEAD` points to the `main` branch.

When you commit, Git advances the current branch to the new commit.

If you check out a specific commit without switching to a branch, Git enters **detached HEAD** state, and `HEAD` contains a commit hash directly.

### `index` — The staging area

When you run:

```
git add hello.txt
```

Git updates the index to stage the version of `hello.txt` that you want included in the next commit.

The index is a binary file, so you shouldn't read it using `cat`.

Instead, use:

```
git ls-files --stage
```

This displays staged file entries, including their object IDs and file modes.

### `logs/` — Reference history

Git records reference movements in reflogs.

For example:

```
git reflog
```

This shows movements such as:

- Commits
    
- Checkouts
    
- Resets
    
- Rebases
    

Reflogs can help recover commits that are no longer reachable through a branch.

They're local records and aren't guaranteed to be retained forever.

### `hooks/` — Automated Git scripts

Git hooks execute custom scripts when certain Git operations occur.

Examples:

|Hook|When it runs|
|---|---|
|`pre-commit`|Before creating a commit|
|`commit-msg`|During commit-message validation|
|`pre-push`|Before pushing|
|`post-commit`|After creating a commit|

For example, a `pre-commit` hook can run tests before allowing a commit.

### `rr-cache/` and `MERGE_RR` — Conflict resolution memory

Git has a feature called **rerere** (reuse recorded resolution).

It can remember how you resolved a merge conflict and reuse that resolution if the same conflict appears again.

- `MERGE_RR` tracks relevant current conflicts.
    
- `rr-cache/` stores recorded conflict preimages and resolutions.
    

These files can appear after using Git's rerere functionality.

## 4. How everything works together

Consider these commands:

```
echo "Hello Git" > hello.txt

git add hello.txt

git commit -m "First commit"
```

Here's what happens internally:

1. You create `hello.txt` in your working directory.
    
2. `git add` stores the file contents as a blob object and updates the index.
    
3. `git commit` creates a tree representing the staged snapshot.
    
4. Git creates a commit object referring to that tree.
    
5. Your current branch reference moves to the new commit.
    
6. Git updates relevant reflogs to record the reference movement.
    

You can think of the overall relationship like this:

```
Working Directory
       |
       | git add
       v
.git/index
       |
       | git commit
       v
.git/objects/
       |
       | Commit created
       v
.git/refs/heads/main
       |
       | HEAD references main
       v
.git/HEAD
```

The arrows are conceptual: the commit object is stored in `objects/`, while the branch reference contains its object ID.

## 5. Useful commands for investigating `.git/`

```
# Show the current HEAD reference
cat .git/HEAD

# Inspect local Git configuration
git config --local --list

# Show references
git show-ref

# Inspect staged entries
git ls-files --stage

# Inspect a commit object
git cat-file -p HEAD

# Inspect reference history
git reflog

# Show object storage statistics
git count-objects -v

# View the repository directory structure
tree .git
```

**Important:** Don't manually delete or modify files inside `.git/` unless you understand the consequences. Changing the wrong reference or object can damage your repository.

## 6. The whole picture

There are three essential concepts to understand first:

|Git component|What it represents|
|---|---|
|Working directory|The files you're editing|
|Index (`.git/index`)|The snapshot being prepared for the next commit|
|Object database (`.git/objects/`)|Stored Git objects representing content and history|

Branches, `HEAD`, and other references tell Git which commits are relevant to your current work.

**The key idea:** Git is fundamentally a content-addressed object database with a version-control interface built around it. Commands such as `add`, `commit`, `branch`, and `checkout` manipulate objects, references, the index, and your working directory.



[[Git & Github]]