

This guide explains how to use common **porcelain** and **plumbing** Git commands, including their syntax and practical examples. Porcelain commands are high-level and user-friendly, while plumbing commands are low-level and suited for scripting or advanced tasks.

## Porcelain Commands

Porcelain commands are designed for everyday Git workflows, offering intuitive interfaces for managing repositories.

### 1. `git add`

**Description**: Stages changes (new, modified, or deleted files) for the next commit.  
**Syntax**: `git add <file(s)>`  
**Examples**:

- Stage a single file:
    
    ```bash
    git add index.html
    ```
    
    Stages `index.html` for the next commit.
- Stage all changes in the current directory:
    
    ```bash
    git add .
    ```
    
    Stages all modified and new files.
- Stage specific changes interactively:
    
    ```bash
    git add -p
    ```
    
    Allows you to review and select specific changes (hunks) to stage.

### 2. `git commit`

**Description**: Saves staged changes to the repository with a descriptive message.  
**Syntax**: `git commit -m "<message>"`  
**Examples**:

- Commit staged changes with a message:
    
    ```bash
    git commit -m "Add new homepage layout"
    ```
    
    Creates a commit with the specified message.
- Commit all modified files directly:
    
    ```bash
    git commit -a -m "Update styles"
    ```
    
    Automatically stages and commits tracked files.
    The `-a` option means:

> Stage modifications and deletions of **already tracked files**, then commit them.

git commit -a -m "Update styles" *only stages and commits modified (or deleted) files that are already tracked** by Git. It *does not include new/untracked files.

### 3. `git push`

**Description**: Uploads local commits to a remote repository.  
**Syntax**: `git push <remote> <branch>`  
**Examples**:

- Push commits to the `main` branch on `origin`:
    
    ```bash
    git push origin main
    ```
    
    Sends local `main` branch commits to the remote repository.
- Force push (use with caution):
    
    ```bash
    git push --force origin main
    ```
    
    Overwrites the remote branch with local changes.

### 4. `git pull`

**Description**: Fetches and merges changes from a remote repository into the current branch.  
**Syntax**: `git pull <remote> <branch>`  
**Examples**:

- Pull changes from `origin/main`:
    
    ```bash
    git pull origin main
    ```
    
    Fetches and merges remote changes into the current branch.
- Pull with rebase instead of merge:
    
    ```bash
    git pull --rebase origin main
    ```
    
    Rebases local changes on top of fetched changes.

### 5. `git branch`

**Description**: Manages branches (create, list, or delete).  
**Syntax**: `git branch [<branch-name>]` or `git branch -d <branch-name>`  
**Examples**:

- List all branches:
    
    ```bash
    git branch
    ```
    
    Shows all local branches, with the current branch marked by `*`.
- Create a new branch:
    
    ```bash
    git branch feature-x
    ```
    
    Creates a branch named `feature-x`.
- Delete a branch:
    
    ```bash
    git branch -d feature-x
    ```
    
    Deletes the `feature-x` branch if it’s merged.

### 6. `git merge`

**Description**: Combines changes from one branch into the current branch.  
**Syntax**: `git merge <branch>`  
**Examples**:

- Merge `feature-x` into the current branch:
    
    ```bash
    git merge feature-x
    ```
    
    Integrates changes from `feature-x` into the current branch.
- Abort a merge with conflicts:
    
    ```bash
    git merge --abort
    ```
    
    Cancels the merge and restores the previous state.

### 7. `git status`

**Description**: Displays the current state of the working directory and staging area.  
**Syntax**: `git status`  
**Examples**:

- Check repository status:
    
    ```bash
    git status
    ```
    
    Shows staged, unstaged, and untracked files.
- Shortened output:
    
    ```bash
    git status -s
    ```
    
    Displays a compact, machine-readable status.

### 8. `git log`

**Description**: Shows the commit history of the repository.  
**Syntax**: `git log`  
**Examples**:

- View commit history:
    
    ```bash
    git log
    ```
    
    Displays commits with details (hash, author, date, message).
- Show a concise log:
    
    ```bash
    git log --oneline
    ```
    
    Lists commits in a single line per commit.
- Show changes for a specific file:
    
    ```bash
    git log --follow <file>
    ```
    
    Tracks history of a file, including renames.



---


## Plumbing Commands

Plumbing commands are low-level, designed for scripting or advanced tasks, manipulating Git’s internal data structures.

### 1. `git cat-file`

**Description**: Displays the contents or metadata of Git objects (blobs, trees, commits, tags).  
**Syntax**: `git cat-file <type> <object-hash>`  
**Examples**:

- View the contents of a blob:
    
    ```bash
    git cat-file blob <hash>
    ```
    
    Prints the contents of the file identified by `<hash>`.
- View commit details:
    
    ```bash
    git cat-file commit <hash>
    ```
    
    Shows metadata (e.g., tree, parent, author) for the commit.
- Check object type:
    
    ```bash
    git cat-file -t <hash>
    ```
    
    Outputs the type of the object (e.g., `blob`, `commit`).

### 2. `git hash-object`

**Description**: Computes the hash of a file or creates a blob object in the Git database.  
**Syntax**: `git hash-object [-w] <file>`  
**Examples**:

- Compute the hash of a file:
    
    ```bash
    git hash-object file.txt
    ```
    
    Outputs the SHA-1 hash of `file.txt`.
- Create a blob object:
    
    ```bash
    git hash-object -w file.txt
    ```
    
    Stores `file.txt` as a blob in the Git database and returns its hash.

### 3. `git update-index`

**Description**: Modifies the Git index (staging area) directly.  
**Syntax**: `git update-index [--add] [--remove] <file>`  
**Examples**:

- Add a file to the index:
    
    ```bash
    git update-index --add file.txt
    ```
    
    Stages `file.txt` without using `git add`.
- Mark a file as unchanged:
    
    ```bash
    git update-index --assume-unchanged file.txt
    ```
    
    Ignores future changes to `file.txt` in the index.

### 4. `git write-tree`

**Description**: Creates a tree object from the current index (staged files).  
**Syntax**: `git write-tree`  
**Examples**:

- Create a tree object:
    
    ```bash
    git write-tree
    ```
    
    Outputs the SHA-1 hash of the tree object representing the current index.
- Use in scripting to capture a snapshot:
    
    ```bash
    TREE_HASH=$(git write-tree)
    echo "Tree hash: $TREE_HASH"
    ```
    
    Stores the tree hash for further operations.

### 5. `git commit-tree`

**Description**: Creates a commit object from a tree and optional parent commits.  
**Syntax**: `git commit-tree <tree-hash> [-p <parent-hash>] -m "<message>"`  
**Examples**:

- Create a commit from a tree:
    
    ```bash
    git commit-tree <tree-hash> -m "Initial commit"
    ```
    
    Creates a commit object and outputs its hash.
- Create a commit with a parent:
    
    ```bash
    git commit-tree <tree-hash> -p <parent-hash> -m "Second commit"
    ```
    
    Links the new commit to a parent commit.

### 6. `git update-ref`

**Description**: Updates a branch or tag reference to point to a specific commit.  
**Syntax**: `git update-ref <ref> <commit-hash>`  
**Examples**:

- Update the `main` branch:
    
    ```bash
    git update-ref refs/heads/main <commit-hash>
    ```
    
    Points the `main` branch to the specified commit.
- Create a new tag:
    
    ```bash
    git update-ref refs/tags/v1.0 <commit-hash>
    ```
    
    Creates a tag `v1.0` pointing to the commit.

### 7. `git rev-parse`

**Description**: Resolves references (e.g., branch names, tags) to their corresponding commit hashes or other Git objects.  
**Syntax**: `git rev-parse <reference>`  
**Examples**:

- Get the hash of the current HEAD:
    
    ```bash
    git rev-parse HEAD
    ```
    
    Outputs the SHA-1 hash of the current commit.
- Resolve a branch name:
    
    ```bash
    git rev-parse origin/main
    ```
    
    Outputs the commit hash for the `main` branch on `origin`.

### 8. `git ls-files`

**Description**: Lists files in the index or working tree.  
**Syntax**: `git ls-files [<options>]`  
**Examples**:

- List all files in the index:
    
    ```bash
    git ls-files
    ```
    
    Shows all tracked files in the current index.
- List modified files:
    
    ```bash
    git ls-files -m
    ```
    
    Displays files with changes in the working directory.
- List untracked files:
    
    ```bash
    git ls-files --others
    ```
    
    Shows untracked files in the working directory.

## Notes

- **Porcelain Commands**: Use these for daily tasks like committing, branching, or checking repository status. They are designed to be intuitive and handle complex operations automatically.
- **Plumbing Commands**: Use these for scripting or when you need precise control over Git’s internals (e.g., creating custom workflows or tools). They require a deeper understanding of Git’s object model (blobs, trees, commits).
- **Safety**: Be cautious with plumbing commands, as they directly manipulate Git’s data structures and can lead to errors if misused.
- **Context**: Ensure you’re in a Git repository (`git init` or `git clone`) before running these commands.
- **Documentation**: For more details, use `git help <command>` or check the [official Git documentation](https://git-scm.com/docs).


#### *Tags : [[0 - Git 🍋‍🟩]]