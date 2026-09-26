

# Viewing Remote Info with `git log`

You can use `git log` to **inspect commits on remote branches** (like `origin/main`, `upstream/main`) since fetch downloads them into remote-tracking branches.

## View Log of a Remote Branch

```bash
git log origin/main
git log upstream/main
git log origin/feature-x
```

## Compare Local vs Remote

**What's on the remote but not local (incoming changes):**
```bash
git log main..origin/main
```
Shows commits that exist on `origin/main` but **not** on your local `main` — i.e., what you'd get from a pull.

**What's local but not on the remote (outgoing changes):**
```bash
git log origin/main..main
```
Shows commits you have that haven't been pushed yet.

**Both directions (diverged):**
```bash
git log main...origin/main --left-right
```
- `<` = commits only on local `main`
- `>` = commits only on `origin/main`

## Compact One-Line View

```bash
git log --oneline main..origin/main
git log --oneline --graph --all
```

`--graph --all` is great for seeing how local and remote branches relate:
```bash
git log --oneline --graph --decorate --all
```

## Show Remote URL / Info

`git log` won't show remote URLs — use these instead:

```bash
git remote -v                    # URLs of all remotes
git remote show origin           # detailed info about origin
git remote show upstream         # branches, tracking, push/pull config
```

Example `git remote show origin` output:
```
* remote origin
  Fetch URL: git@github.com:yourname/react.git
  Push  URL: git@github.com:yourname/react.git
  HEAD branch: main
  Remote branches:
    main    tracked
    dev     tracked
  Local branch configured for 'git pull':
    main merges with remote main
```

## List All Remote Branches

```bash
git branch -r                    # list remote-tracking branches
git branch -a                    # list local + remote branches
git ls-remote origin             # list refs directly from the remote (no fetch)
```

## Common Patterns

**"What did I fetch just now?"**
```bash
git log --oneline HEAD..origin/main
```

**"Am I ahead or behind?"**
```bash
git log --oneline --left-right main...origin/main
```

**"See all history including remotes, as a graph"**
```bash
git log --oneline --graph --decorate --all
```

**"Show commits on upstream not in my fork"**
```bash
git log --oneline origin/main..upstream/main
```

## Quick Reference

| Goal | Command |
|------|---------|
| Log a remote branch | `git log origin/main` |
| Incoming (not yet pulled) | `git log main..origin/main` |
| Outgoing (not yet pushed) | `git log origin/main..main` |
| Diverged, both sides | `git log --left-right main...origin/main` |
| All branches, graph | `git log --oneline --graph --all` |
| List remote branches | `git branch -r` |
| Remote URLs | `git remote -v` |
| Detailed remote info | `git remote show origin` |
| Query remote without fetching | `git ls-remote origin` |

## Note

`git log` on a remote branch only works **after a fetch** — the data must exist locally as a remote-tracking ref. To see live remote state without fetching:
```bash
git ls-remote origin
```



[[0 - Git 🍋‍🟩]]