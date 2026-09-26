##### Tags : [[0 - Git 🍋‍🟩]]

A **Git repository** is a directory storing a project's files and Git's version control data (in `.git/`), tracking changes and enabling collaboration. It can be local (on your machine) or remote (e.g., GitHub).

## Key Components

- **Working Directory**: Project files you edit (e.g., `index.html`).
- **Staging Area**: Prepares changes for commits (via `git add`).
- **.git Directory**: Stores commit history, branches, tags, and config (`.git/config`).
- **Remote References**: Links to remote repos (e.g., `origin`).

## Initializing a Git Repository

Create a new local repository:

```bash
git init my-project
```

- Creates `my-project/.git/` with Git metadata.
- Example: Initialize and set user details.
    
    ```bash
    cd my-project
    git init
    git config --local user.name "Your Name"
    git config --local user.email "your.email@example.com"
    ```
    

Add multiple config values (e.g., aliases) with `--add`:

```bash
git config --local --add alias.st status
git config --local --add alias.lg "log --oneline"
```

## Inspecting with `find` and `cat`

Use Linux commands to explore the repository:

- **List `.git/` contents**:
    
    ```bash
    find .git/ -type f
    ```
    
    - Shows files like `.git/HEAD`, `.git/config`, `.git/refs/heads/main`.
- **View file contents**:
    
    ```bash
    cat .git/config
    ```
    
    - Displays repository config, e.g.:
        
        ```bash
        [core]
            repositoryformatversion = 0
            filemode = true
            bare = false
        [user]
            name = Your Name
            email = your.email@example.com
        [alias]
            st = status
            lg = log --oneline
        ```
        
	- **Check current branch**:
    
    ```bash
    cat .git/HEAD
    ```
    
    - Output: `ref: refs/heads/main`

---



## Basic Commands

- Stage files: `git add <file>` or `git add .`
- Commit: `git commit -m "Initial commit"`
- Check status: `git status`

## Tips

- Avoid editing `.git/` manually to prevent corruption.
- Use `git config --list` to verify settings.
- For more, run `git help` or check [Git documentation](https://git-scm.com/docs).

