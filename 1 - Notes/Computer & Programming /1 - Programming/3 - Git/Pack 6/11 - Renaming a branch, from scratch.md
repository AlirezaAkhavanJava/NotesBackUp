

## 1. What you're actually changing

A branch is just a label pointing at a commit. Renaming changes the **label**, not the commits. Your history, files, and work stay exactly as they are.

One catch: a branch can exist in two places.

- **Local branch**: the label in your own repo (`old-name`)
- **Remote branch**: the label on a server like GitHub (`origin/old-name`)

Git can rename the local one directly. The remote one can't be renamed; you create a new name and delete the old one.

## 2. Rename the local branch

**If you're on the branch you want to rename:**

```bash
git branch -m new-name
```

**If you're on a different branch:**

```bash
git branch -m old-name new-name
```

`-m` means **move** (as in `mv`, the Unix rename command). Same idea: moving something to a new name.

If `new-name` already exists and you want to overwrite it, use `-M` (force move):

```bash
git branch -M new-name
```

You'll see this a lot in tutorials: `git branch -M main` is the common way to rename your first branch from `master` to `main`.

## 3. Rename the remote branch

Do the local rename first, then:

```bash
git push origin -u new-name          # push the new name, set tracking
git push origin --delete old-name    # remove the old name from the server
```

- `-u` links your local `new-name` to `origin/new-name`, so plain `git push` and `git pull` work later.
- `--delete` removes the old label from the remote.

## 4. Full walkthrough

Say you're on `feature-x` and want `login-page`:

```bash
git branch -m login-page
git push origin -u login-page
git push origin --delete feature-x
```

Check the result:

```bash
git branch -vv      # local branches and what they track
git branch -r       # remote branches
```

## 5. Pitfalls

- **Teammates are affected.** If others use the old remote name, their copy breaks after you delete it. Tell them to run:
    
    ```bash
    git fetch --prunegit branch -m old-name new-namegit branch -u origin/new-name new-name
    ```
    
- **Open pull requests** on the old branch name are usually closed or broken when you delete it. On GitHub, renaming through the web UI (Settings → Branches) handles this better, since it retargets PRs.
- **Protected branches** (like `main`) may refuse deletion until you change the default branch in your hosting settings.
- **Old tracking** can linger. If `git status` still mentions the old upstream, fix it with `git branch -u origin/new-name`.

## Summary

|Goal|Command|
|---|---|
|Rename current branch|`git branch -m new-name`|
|Rename another branch|`git branch -m old new`|
|Force overwrite|`git branch -M new-name`|
|Update the remote|`git push origin -u new` then `git push origin --delete old`|





[[Git & Github]]