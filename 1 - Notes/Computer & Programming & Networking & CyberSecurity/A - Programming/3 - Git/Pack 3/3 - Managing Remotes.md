

A **remote** is just a named pointer to another repository's URL (usually on GitHub/GitLab) that your local repo can fetch from or push to.

---

## Add / Drop a Remote

```bash
git remote add <name> <url>        # add a new remote
git remote remove <name>            # remove a remote
git remote rm <name>                # same as above (alias)
```

**Example:**

```bash
git remote add origin https://github.com/AlirezaAkhavanJava/webflyx.git
git remote remove origin
```

> Removing a remote doesn't delete anything on the server or affect your commits — it just removes the local pointer/reference to it. Your remote-tracking branches (`origin/main`, etc.) get deleted too, but your local branches and history are untouched.

---

## Common Remote Commands

|Command|What it does|
|---|---|
|`git remote`|List remote names only|
|`git remote -v`|List remotes with their URLs (fetch + push)|
|`git remote show <name>`|Detailed info: tracked branches, ahead/behind status|
|`git remote add <name> <url>`|Add a new remote|
|`git remote remove <name>`|Remove a remote|
|`git remote rename <old> <new>`|Rename a remote|
|`git remote set-url <name> <new-url>`|Change a remote's URL (e.g. switch HTTPS → SSH)|
|`git remote set-url --push <name> <url>`|Set a _different_ URL just for pushing (rare, advanced use)|
|`git remote get-url <name>`|Print a remote's URL|
|`git remote prune <name>`|Delete local references to remote branches that no longer exist on the server|
|`git remote update`|Fetch updates from all remotes at once|

---

## Fetch / Push / Pull with a Remote

|Command|What it does|
|---|---|
|`git fetch <remote>`|Download objects/refs from remote, don't merge|
|`git fetch --all`|Fetch from every configured remote|
|`git push <remote> <branch>`|Push a branch to remote|
|`git push -u <remote> <branch>`|Push and set upstream tracking (only needed once per branch)|
|`git pull <remote> <branch>`|Fetch + merge in one step|
|`git branch -vv`|Show local branches with their tracked remote branch and ahead/behind status|

---

## Example Workflow (Your Naming Convention)

```bash
git remote add origin https://github.com/AlirezaAkhavanJava/webflyx.git
git remote -v
```

```
origin  https://github.com/AlirezaAkhavanJava/webflyx.git (fetch)
origin  https://github.com/AlirezaAkhavanJava/webflyx.git (push)
```

If you switch from HTTPS to SSH later (common once you set up SSH keys):

```bash
git remote set-url origin git@github.com:AlirezaAkhavanJava/webflyx.git
```

---

**One-line definition to remember:**

> A remote is a saved shortcut (name → URL) for a repository elsewhere — `origin` is just the conventional default name for "the main remote," not a special keyword.

Want to go through **SSH key setup on Debian** next so you can switch `webflyx` from HTTPS to SSH and stop typing your GitHub password/token every push?


[[0 - Git 🍋‍🟩]]