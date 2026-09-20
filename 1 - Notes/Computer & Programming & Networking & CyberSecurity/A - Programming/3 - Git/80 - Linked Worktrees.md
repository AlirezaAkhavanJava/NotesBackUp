![[Pasted image 20251119162742.png]]
### What are Linked Worktrees?

**Linked worktrees** (introduced in Git 2.17, 2018) are a special type of worktree where the `.git` file in the worktree directory is not a plain file pointing to the main repository, but instead a **symbolic link** (symlink) pointing directly to the real `.git` directory of the main worktree.

This feature is mainly useful on **Windows** and in some advanced setups where a plain `.git` file (which is a Git-specific "gitdir: path" pointer) causes issues with tools or scripts that don’t understand Git’s custom format.

### Normal worktree vs Linked worktree

| Type               | `.git` in the worktree                  | Created with               | Default on Unix/macOS | Default on Windows | Compatibility |
|--------------------|-----------------------------------------|----------------------------|-----------------------|--------------------|---------------|
| Regular worktree   | A plain file containing `gitdir: /path/to/main/.git/worktrees/name` | `git worktree add` (default) | Yes                   | No (before Git 2.17) | Most tools understand it |
| Linked worktree    | A real symlink → points to main `.git`  | `git worktree add --symlink` or Git on Windows ≥2.17+ | Optional              | Yes (default)        | Some old tools/scripts break |

### How to create a linked worktree

```bash
# Explicitly create a linked worktree (works on any OS that supports symlinks)
git worktree add --symlink ../myproject-feature feature/login

# On modern Windows Git, this happens automatically (no flag needed)
git worktree add ../myproject-hotfix hotfix/bug-123   # → creates symlink
```

You’ll see something like this on Unix/macOS when using `--symlink`:

```bash
$ ls -la myproject-feature
lrwxr-xr-x  .git -> /path/to/main/repo/.git
```

On Windows it looks the same in Git Bash or when viewed with `dir /a`.

### When linked worktrees matter

| Scenario                                    | Regular worktree | Linked worktree |
|---------------------------------------------|------------------|-----------------|
| Default behavior on Windows (Git ≥2.17)     | Not created      | Created automatically |
| Some build tools or IDEs that traverse `.git` as a real directory | May fail         | Works           |
| Running Git from inside the worktree on Windows | Sometimes issues | Smoother        |
| You want maximum compatibility with non-Git-aware tools | Risky            | Safer           |

### Gotchas & limitations

- **Symlinks require permission**  
  On Unix/macOS you usually need no special rights.  
  On Windows you need either:
  - Administrator/Developer Mode enabled, or
  - Git configured to allow it: `git config core.symlinks true`

- **Not all filesystems support symlinks**  
  (e.g., FAT32 USB sticks, some network shares)

- **Some very old tools** still choke on symlinked `.git` directories (extremely rare now).

- You can mix both types in the same repository:
  ```bash
  git worktree add ../regular-worktree feature/a      # regular .git file
  git worktree add --symlink ../linked-worktree feature/b   # symlink
  ```

### How to check what you have

```bash
git worktree list --porcelain

# Output includes:
worktree /path/to/main
bare

worktree /path/to/regular
gitdir: /path/to/main/.git/worktrees/regular   # ← regular

worktree /path/to/linked
gitdir: /path/to/main/.git                     # ← linked (symlink)
```

### Summary: Do you need to care?

| Your OS / Situation                  | Do this                                      |
|--------------------------------------|----------------------------------------------|
| Linux / macOS                        | Almost never need `--symlink`                |
| Windows (modern Git)                 | You already get linked worktrees by default |
| Using tools that break with plain `.git` file on Windows | You’re already safe                          |
| Cross-platform scripts or old Windows | Stick with defaults or force `--symlink` if needed |

In 99% of cases today, **you don’t have to think about linked worktrees at all** — Git does the right thing automatically.

Just keep using `git worktree add` as usual, and on Windows you’re quietly getting the more compatible linked version. 🚀

---


When you make a change in a _linked_ worktree, that change is automatically reflected in the _main_ worktree!

It makes sense: the linked worktree doesn't have a `.git` directory, so it's not a separate repository. It's just a different view of the _same_ repository.

You can almost think of a linked worktree as just another branch in the same repo, but with its own space on the filesystem.



###### Tags : [[0 - Git 🍋‍🟩]]