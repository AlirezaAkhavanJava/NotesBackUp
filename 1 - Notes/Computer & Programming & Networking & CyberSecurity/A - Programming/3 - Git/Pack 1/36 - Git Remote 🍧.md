`git remote` is a Git command used to **manage remote repositories** (i.e., versions of your project hosted on a server like GitHub, GitLab, Bitbucket, etc.).

---

### Basic Syntax
```bash
git remote [-v | --verbose]
```

---

### Common Usage

#### 1. **List all remotes**
```bash
git remote
```
- Output: Names of remote repositories (e.g., `origin`).

#### 2. **List remotes with URLs (verbose)**
```bash
git remote -v
```
**Example output:**
```
origin  https://github.com/user/repo.git (fetch)
origin  https://github.com/user/repo.git (push)
```

---

### Other `git remote` Subcommands

| Command | Purpose |
|-------|--------|
| `git remote add <name> <url>` | Add a new remote |
| `git remote remove <name>` | Remove a remote |
| `git remote rename <old> <new>` | Rename a remote |
| `git remote set-url <name> <newurl>` | Change remote URL |
| `git remote show <name>` | Show detailed info about a remote |
| `git remote prune <name>` | Clean up stale branches |

---

### Examples

#### Add a new remote
```bash
git remote add upstream https://github.com/original/repo.git
```

#### Change remote URL
```bash
git remote set-url origin git@github.com:user/repo.git
```

#### View detailed info
```bash
git remote show origin
```
Shows:
- Remote URL
- Branch tracking info
- Push/pull refs

---

### Common Remote: `origin`
- `origin` is the **default name** Git gives to the remote repository you cloned from.

---

### Tips
- Use `git remote -v` often to verify where your code is pushing/pulling.
- Multiple remotes are useful (e.g., `origin` = your fork, `upstream` = original repo).

---


##### Tags : [[0 - Git 🍋‍🟩]]