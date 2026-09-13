`git push` sends your committed changes from the local branch to the remote repository.

### Basic Usage
```bash
git push origin <branch-name>
```
- `origin`: Default remote name (check with `git remote -v`).
- `<branch-name>`: Usually the current branch (e.g., `main` or `feature/login`).

**Example:**
```bash
git push origin main
```

### Common Scenarios

1. **First push of a new branch** (sets upstream):
   ```bash
   git push -u origin my-new-branch
   ```
   The `-u` flag links your local branch to the remote for future `git push/pull` without arguments.

2. **Push current branch only**:
   ```bash
   git push
   ```
   Works if upstream is set (via `-u` previously).

3. **Force push** (use with caution—rewrites history):
   ```bash
   git push --force-with-lease origin main
   ```
   Safer than `--force`; aborts if remote has new commits.

4. **Push all branches**:
   ```bash
   git push --all origin
   ```

5. **Push tags**:
   ```bash
   git push --tags
   ```

### Common Errors & Fixes

| Error | Cause | Fix |
|------|-------|-----|
| `fatal: The current branch has no upstream branch` | First push, no tracking set | Use `git push -u origin <branch>` |
| `rejected: non-fast-forward` | Remote has newer commits | `git pull --rebase` first, then push |
| `permission denied` | Wrong credentials or no access | Check SSH key or HTTPS token |
| `src refspec main does not match any` | No commits yet | `git commit` something first |

### Quick Checklist Before Pushing
```bash
git status          # Ensure working directory is clean
git log --oneline   # Verify commits to push
git pull --rebase   # Sync with remote
git push            # Push!
```



##### Tags : [[0 - Git 🍋‍🟩]]