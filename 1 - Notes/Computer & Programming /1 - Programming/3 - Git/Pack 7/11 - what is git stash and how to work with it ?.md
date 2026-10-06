

# Git Stash

`git stash` temporarily shelves your uncommitted changes (both staged and unstaged modifications to tracked files) so you get a clean working directory, without having to commit half-finished work. You can bring the changes back later.

**Typical use case:** you're mid-feature, and a bug report comes in. You need to switch branches, but your changes aren't ready to commit. Stash, switch, fix, come back, restore.

## Basic workflow

```bash
git stash              # save changes and clean the working directory
git switch other-branch
# ...do other work...
git switch original-branch
git stash pop          # restore the changes and remove them from the stash
```

## Essential commands

|Command|What it does|
|---|---|
|`git stash` or `git stash push`|Stash tracked changes|
|`git stash push -m "message"`|Stash with a descriptive name|
|`git stash list`|Show all stashes|
|`git stash show`|Summary of the latest stash|
|`git stash show -p`|Full diff of the latest stash|
|`git stash pop`|Apply the latest stash **and** delete it|
|`git stash apply`|Apply the latest stash **but keep it** in the list|
|`git stash drop`|Delete the latest stash|
|`git stash clear`|Delete all stashes|

## Working with multiple stashes

Stashes form a stack, referenced as `stash@{0}` (newest), `stash@{1}`, and so on:

```bash
git stash list
# stash@{0}: On main: login form WIP
# stash@{1}: On main: refactor api client

git stash apply stash@{1}    # apply a specific one
git stash drop stash@{1}     # delete a specific one
```

Naming your stashes with `-m` makes this much easier.

## Including other kinds of files

By default, stash ignores untracked and ignored files.

```bash
git stash -u            # also stash untracked files (--include-untracked)
git stash -a            # also stash ignored files (--all)
git stash push path/to/file.js   # stash only specific files
git stash -p            # interactively choose which hunks to stash
git stash --keep-index  # stash only unstaged changes, leaving staged ones in place
```

## Useful extras

**Create a branch from a stash** (handy if the stash no longer applies cleanly):

```bash
git stash branch new-branch-name stash@{0}
```

This creates the branch from the commit you stashed on, applies the stash, and drops it if successful.

**Handling conflicts:** if `pop` conflicts with your current code, Git leaves the conflicts for you to resolve, and the stash is _not_ dropped. After resolving, drop it manually with `git stash drop`.

## Tips and gotchas

- Stashes are **local**; they aren't pushed to remotes.
- Stashes are tied to no branch, so you can pop them anywhere (but conflicts are likelier on a very different branch).
- Prefer `apply` over `pop` when you're unsure the changes will apply cleanly.
- Stashes pile up and get forgotten. For longer-term work, a WIP commit or a branch is usually better.
- An accidentally dropped stash can sometimes be recovered with `git fsck --unreachable | grep commit`, but don't rely on it.


[[Git & Github]]