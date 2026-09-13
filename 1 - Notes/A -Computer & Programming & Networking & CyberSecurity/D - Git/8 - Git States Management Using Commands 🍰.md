

This document outlines the Git commands used to manage the different states of files in a Git repository: untracked, modified (unstaged), staged, committed, and pushed.

## Managing Untracked Files

- **Track a File (Move to Staged)**:
    
    ```bash
    git add <file>
    ```
    
- **Track All Files**:
    
    ```bash
    git add .
    ```
    
- **Remove Untracked Files**:
    
    ```bash
    git clean -f
    ```
    
- **Preview Files to be Removed**:
    
    ```bash
    git clean -n
    ```
    
- **Ignore Files**:
    
    ```bash
    echo "<file>" >> .gitignore
    ```
    

## Managing Modified (Unstaged) Files

- **Stage Modified File**:
    
    ```bash
    git add <file>
    ```
    
- **Discard Changes**:
    
    ```bash
    git restore <file>
    ```
    
- **View Changes**:
    
    ```bash
    git diff <file>
    ```
    

## Managing Staged Files

- **Commit Staged Files**:
    
    ```bash
    git commit -m "Commit message"
    ```
    
- **Unstage Files (Move to Modified)**:
    
    ```bash
    git restore --staged <file>
    ```
    
- **View Staged Changes**:
    
    ```bash
    git diff --staged
    ```
    

## Managing Committed Files

- **View Commit History**:
    
    ```bash
    git log
    ```
    
- **Concise Commit History**:
    
    ```bash
    git log --oneline
    ```
    
- **Amend Last Commit**:
    
    ```bash
    git commit --amend
    ```
    
- **Revert a Commit**:
    
    ```bash
    git revert <commit-hash>
    ```
    
- **Reset to Previous Commit**:
    
    ```bash
    git reset --hard <commit-hash>
    ```
    

## Managing Pushed Files

- **Push to Remote**:
    
    ```bash
    git push origin <branch>
    ```
    
- **Fetch Remote Changes**:
    
    ```bash
    git fetch origin
    ```
    
- **Merge Remote Changes**:
    
    ```bash
    git merge origin/<branch>
    ```
    
- **Pull Remote Changes**:
    
    ```bash
    git pull origin <branch>
    ```
    
- **Force Push**:
    
    ```bash
    git push --force
    ```



##### *Tags : [[0 - Git 🍋‍🟩]]