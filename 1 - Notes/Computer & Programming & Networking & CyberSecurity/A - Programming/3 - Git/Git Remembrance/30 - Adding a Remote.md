





A **remote** is a named reference to another copy of your repository (usually on a server like GitHub, GitLab, or Bitbucket). Adding one lets you fetch from and push to that location.

## Basic Syntax

```bash
git remote add <name> <url>
```

- **`<name>`** — the alias you'll use (e.g., `origin`, `upstream`, `fork2`)
- **`<url>`** — the repository location (HTTPS or SSH)

## Common Examples

**Add the original repo as `upstream` (fork workflow):**
```bash
git remote add upstream https://github.com/facebook/react.git
```

**Add another collaborator's fork:**
```bash
git remote add colleague https://github.com/theirname/react.git
```

**Add using SSH instead of HTTPS:**
```bash
git remote add upstream git@github.com:facebook/react.git
```

## Verify It Worked

```bash
git remote -v
```
Output:
```
origin     git@github.com:yourname/react.git (fetch)
origin     git@github.com:yourname/react.git (push)
upstream   https://github.com/facebook/react.git (fetch)
upstream   https://github.com/facebook/react.git (push)
```

## Using the Remote

Once added, you can reference it by name:

```bash
git fetch upstream              # download branches/commits (doesn't merge)
git fetch upstream main         # fetch a specific branch
git pull upstream main          # fetch + merge into current branch
git push origin main            # push to your fork
git checkout -b feature upstream/main   # branch off upstream's main
```

## Naming Rules

- Can be almost anything: `origin`, `upstream`, `staging`, `backup`, etc.
- **Convention**: `origin` = your fork/clone source, `upstream` = the original project
- Names are **case-sensitive** and shouldn't contain spaces

## Related Commands

```bash
git remote -v                    # list remotes with URLs
git remote show upstream         # detailed info (branches, tracking)
git remote rename upstream source   # rename a remote
git remote set-url upstream <new-url>  # change URL (HTTPS ↔ SSH)
git remote remove upstream       # delete a remote
git remote prune origin          # clean up stale remote-tracking branches
```

## Common Gotcha

Adding a remote **does not** download anything yet. It just registers the name → URL mapping. Run `git fetch <name>` to actually pull down the refs.

```bash
git remote add upstream https://github.com/facebook/react.git
git fetch upstream               # ← this actually gets the data
```

## HTTPS vs SSH

| | HTTPS | SSH |
|---|-------|-----|
| URL format | `https://github.com/user/repo.git` | `git@github.com:user/repo.git` |
| Auth | Token / password prompt | SSH key |
| Setup | Simpler | Requires key setup |
| Switch with | `git remote set-url origin <ssh-url>` | `git remote set-url origin <https-url>` |

## Summary

1. `git remote add <name> <url>` — register a remote
2. `git remote -v` — verify
3. `git fetch <name>` — download its contents
4. Reference it in `push`, `pull`, `fetch`, `merge`, `rebase` by name


[[0 - Git 🍋‍🟩]]