
### Git Tags – The Complete Guide

Tags in Git are **immutable references** to a specific commit. They are most commonly used to mark release versions (v1.0.0, v2.5.1, etc.).

#### Two types of tags

| Type              | Command to create                          | Stores                                          | Can be signed | Typical use                     |
|-------------------|--------------------------------------------|-------------------------------------------------|---------------|---------------------------------|
| Lightweight       | `git tag v1.0.0`                           | Just a name pointing to a commit                | No            | Internal bookmarks, temporary   |
| Annotated         | `git tag -a v1.0.0 -m "Release 1.0.0"`     | Full tag object (tagger, date, message, etc.)   | Yes           | Official releases (recommended) |

**Always prefer annotated tags for releases** – they carry metadata and can be cryptographically signed.

### Common tag commands

```bash
# Create
git tag v1.2.3                            # lightweight
git tag -a v1.2.3 -m "Stable release"     # annotated
git tag -a v1.2.3 -m "Msg" abc1234        # tag an old commit

# Sign with GPG (highly recommended for public releases)
git tag -s v1.2.3 -m "Signed release"     # uses your default GPG key
git tag -u key-id v1.2.3 -m "Msg"         # specify key

# List tags
git tag                                   # simple list
git tag -l "v2.*"                         # pattern
git tag --list --sort=-version:refname    # sorted by version

# Show tag details
git show v1.2.3

# Push tags to remote
git push origin v1.2.3                    # one tag
git push origin --tags                    # all tags (be careful!)

# Delete tags
git tag -d v1.2.3                         # local
git push origin :refs/tags/v1.2.3         # remote (old syntax)
git push origin --delete v1.2.3           # modern syntax

# Checkout a tag (detached HEAD)
git checkout v1.2.3
# Or create a branch from a tag
git checkout -b release-1.2 v1.2.3
```

### Best practices for releases

```bash
# 1. Make sure you're on the right commit
git checkout main
git pull

# 2. Create and sign an annotated tag
git tag -s v2.5.0 -m "Version 2.5.0 – Major feature release"

# 3. Verify it
git verify-tag v2.5.0   # checks GPG signature
git show v2.5.0

# 4. Push tag (triggers CI/CD, GitHub Releases, etc.)
git push origin v2.5.0
```

### Semantic versioning tags (very common)

Sort tags correctly with `--sort=-version:refname`:

```bash
git tag --list --sort=-version:refname | head -10
# v2.5.0
# v2.4.9
# v2.4.8
# ...
```

### Tags with Git Worktrees

You can safely create worktrees directly from tags:

```bash
git worktree add ../myproject-v1.2.3 v1.2.3   # detached HEAD at the tag
git worktree add -b hotfix-from-1.2 ../fix-123 v1.2.3   # branch from tag
```

### Pro tips

| Goal                                    | Command                                                          |
|-----------------------------------------|------------------------------------------------------------------|
| List all tags with their commit dates   | `git tag --list --format='%(refname:short) %(taggerdate:short)'` |
| Find the latest tag                     | `git describe --tags --abbrev=0`                                 |
| Current commit relative to latest tag   | `git describe --tags` → v2.5.0-14-gabc1234                        |
| Move a tag to new commit                | `git tag -f -a v1.2.3 new-commit` (dangerous on shared repos)   |
| Fetch tags from remote                  | `git fetch --tags`                                               |

### Summary cheat sheet

| Task                          | Command                                      |
|-------------------------------|----------------------------------------------|
| Create release tag            | `git tag -s vX.Y.Z -m "Msg"`                 |
| Push one tag                  | `git push origin vX.Y.Z`                     |
| Push all tags                 | `git push --tags`                            |
| Delete remote tag             | `git push --delete origin vX.Y.Z`            |
| Latest tag                    | `git describe --tags --abbrev=0`             |

Tags are forever (unless force-pushed), so treat them as immutable history markers.


##### Tags : [[0 - Git 🍋‍🟩]]