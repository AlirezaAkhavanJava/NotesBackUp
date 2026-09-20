
![[Pasted image 20251117164646.png]]

> Git stash is a built-in feature in Git, the distributed version control system, that allows you to temporarily save ("stash") your uncommitted changes in your working directory and staging area. This shelves your work in a safe, stack-like structure so you can switch branches, pull updates, or perform other tasks without committing incomplete code. It's especially useful when you need to clean up your working tree quickly but want to resume your changes later.

### How It Works
- **Stashing changes**: Git creates a commit-like snapshot of your modified files (both staged and unstaged) and clears them from your working directory, storing the stash on a stack.
- **The stash stack**: Stashes are stored in a LIFO (last-in, first-out) order, like a stack of cards. You can view, apply, or drop them as needed.
- **Restoring changes**: When you're ready, you can reapply a stash, which restores the saved changes to your working directory (and may cause merge conflicts if the code has diverged).

### Common Commands
Here's a quick reference for the most used `git stash` subcommands:

| Command | Description | Example |
|---------|-------------|---------|
| `git stash push` (or just `git stash`) | Save current changes to a new stash entry on the stack. Optionally add a message with `-m "message"`. | `git stash push -m "WIP on feature branch"` |
| `git stash list` | Show a list of all stashed entries (e.g., `stash@{0}` is the most recent). | `git stash list` |
| `git stash pop` | Apply the most recent stash (default `stash@{0}`) and remove it from the stack. | `git stash pop` |
| `git stash apply` | Apply a stash without removing it from the stack (safer for testing). | `git stash apply stash@{1}` |
| `git stash show` | View a summary of changes in a specific stash. Use `-p` for full diff. | `git stash show -p stash@{0}` |
| `git stash drop` | Remove a stash from the stack without applying it. | `git stash drop stash@{0}` |
| `git stash clear` | Delete all stashes from the stack. | `git stash clear` |

### Use Cases
- **Branch switching**: You've made changes on `main` but need to fix a bug on `develop` first.
- **Emergency pulls**: Incoming changes from `git pull` would conflict with your uncommitted work.
- **Experimenting**: Test a quick idea without polluting your commit history.

### Tips
- Stashes don't include untracked files by default; use `git stash push -u` (or `-a` for all files) to include them.
- If conflicts arise when applying a stash, resolve them manually (like a merge), then commit or stash again.
- Stashes are local to your repository—don't rely on them for long-term storage; commit or create a branch instead.




###### Tags : [[0 - Git 🍋‍🟩]]