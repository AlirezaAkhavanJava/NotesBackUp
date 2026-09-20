# Git States and the `git status` Command

## Git States

Git manages files in a repository through several states, which represent the lifecycle of changes in a project. These states are part of Git's version control system and help track modifications. The main Git states are:

1. **Untracked**: Files in the working directory that Git does not track. These are typically new files not yet added to the repository with `git add`.
2. **Modified (Unstaged)**: Files that have been changed since the last commit but have not been staged for the next commit. These changes exist only in the working directory.
3. **Staged**: Files that have been modified and added to the staging area (index) using `git add`. These changes are ready to be included in the next commit.
4. **Committed**: Files whose changes have been saved in the Git repository's history via `git commit`. These changes are permanently stored in the repository's database.
5. **Pushed (Optional)**: Committed changes that have been uploaded to a remote repository using `git push`. This state applies when working with remote repositories like GitHub or GitLab.

---
### Workflow Example

- Create a new file (`example.txt`): It starts as **untracked**.
- Modify `example.txt`: It becomes **modified** (unstaged).
- Run `git add example.txt`: The file is now **staged**.
- Run `git commit -m "Add example.txt"`: The file is **committed**.
- Run `git push origin main`: The changes are **pushed** to the remote repository.

---
## The `git status` Command

The `git status` command is a fundamental Git command that displays the current state of the working directory and the staging area. It provides a snapshot of which files are in which states, helping you understand what changes are ready to be committed or need attention.

### How It Works

Running `git status` in a Git repository shows:

- **Branch Information**: The current branch (e.g., `On branch main`) and whether it is up to date with the remote repository.
- **Changes to be Committed**: Files in the **staged** state, ready for the next commit.
- **Changes Not Staged for Commit**: Files in the **modified** (unstaged) state, which have changes but haven't been added with `git add`.
- **Untracked Files**: Files in the **untracked** state, which are not yet tracked by Git.
- **Additional Information**: Suggestions for next steps, such as commands to stage, commit, or push changes.

### Example Output

```bash
$ git status
On branch main
Your branch is up to date with 'origin/main'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   README.md

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   src/app.py

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	config.ini
```

### Explanation of Output

- **Branch**: The repository is on the `main` branch, and it is synchronized with the remote (`origin/main`).
- **Changes to be Committed**: `README.md` is staged and will be included in the next commit.
- **Changes Not Staged**: `src/app.py` has modifications but is not staged.
- **Untracked Files**: `config.ini` is a new file not yet tracked by Git.

### Common Uses

- **Check Repository Status**: Quickly see which files have changed and their states.
- **Plan Next Actions**: Determine whether to stage files (`git add`), commit changes (`git commit`), or clean up untracked files.
- **Verify Workflow**: Ensure the repository is in the desired state before pushing changes to a remote repository.

### Useful Options

- `git status -s` or `--short`: Displays a compact version of the status output, showing only the file names and their states.
    - Example: `M README.md` (modified), `A config.ini` (added), `?? newfile.txt` (untracked).
- `git status --ignored`: Shows ignored files (listed in `.gitignore`) in addition to the standard output.

## Summary

Understanding Git states and the `git status` command is essential for effective version control. The states (**untracked**, **modified**, **staged**, **committed**, and **pushed**) represent the lifecycle of file changes, while `git status` provides a clear overview of the repository's current state, guiding you through the next steps in your Git workflow.
###### Tags : [[0 - Git 🍋‍🟩]]