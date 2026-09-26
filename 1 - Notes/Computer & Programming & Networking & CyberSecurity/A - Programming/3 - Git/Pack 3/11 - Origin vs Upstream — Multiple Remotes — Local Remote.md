

## 1. `origin` and `upstream` Are Just Names — Not Special Keywords

Nothing in Git hardcodes the meaning of "origin" or "upstream." They're **naming conventions** everyone follows for clarity — you could name a remote `banana` and Git wouldn't care. But following convention matters for collaborating with others.

```bash
git remote add <any-name-you-want> <url>
```

---

## 2. `origin` — Convention Meaning

**`origin`** = the remote you **cloned from**, or the one you consider "yours" / your primary working remote. Git even sets this automatically:

```bash
git clone https://github.com/AlirezaAkhavanJava/webflyx.git
```

This automatically creates a remote named `origin` pointing at that URL — you never typed `git remote add origin ...` yourself; `clone` does it for you.

---

## 3. `upstream` — Convention Meaning

**`upstream`** = the **original** repository you forked from — used specifically in the **fork workflow** (covered earlier).

```
Original repo (someone else's)  →  called "upstream"
Your fork (your GitHub account)  →  called "origin"
```

```bash
git clone https://github.com/AlirezaAkhavanJava/webflyx.git   # clones YOUR fork → auto-named "origin"
git remote add upstream https://github.com/OriginalOwner/webflyx.git   # manually add the original
```

**Why this matters:** you push your work to `origin` (your fork — you have write access), but pull updates from `upstream` (the original — you don't have write access, only read).

```bash
git fetch upstream
git merge upstream/main       # sync your fork with the original project
git push origin main           # push your own changes to your fork
```

---

## Origin vs Upstream — Quick Table

||`origin`|`upstream`|
|---|---|---|
|Points to|Your own copy (fork or original clone)|The original project (if you forked)|
|Write access?|Yes|Usually no|
|You push here|Yes|No (rarely, only if you're a maintainer)|
|You pull updates from here|Sometimes|Yes — to stay in sync with the original|
|Set automatically?|Yes, by `git clone`|No — you add it manually|

---

## 4. Multiple Remotes — Why and How

You're not limited to one or two remotes. Common reasons to have several:

- **Fork workflow**: `origin` (your fork) + `upstream` (original project)
- **Mirroring**: pushing the same repo to both GitHub and GitLab
- **Backup remote**: a second private server as a safety copy
- **Team remotes**: `origin` (shared team repo) + `personal` (your own backup fork)

```bash
git remote add origin https://github.com/AlirezaAkhavanJava/webflyx.git
git remote add upstream https://github.com/SomeoneElse/webflyx.git
git remote add backup git@gitlab.com:AlirezaAkhavanJava/webflyx.git

git remote -v
```

```
origin    https://github.com/AlirezaAkhavanJava/webflyx.git (fetch)
origin    https://github.com/AlirezaAkhavanJava/webflyx.git (push)
upstream  https://github.com/SomeoneElse/webflyx.git (fetch)
upstream  https://github.com/SomeoneElse/webflyx.git (push)
backup    git@gitlab.com:AlirezaAkhavanJava/webflyx.git (fetch)
backup    git@gitlab.com:AlirezaAkhavanJava/webflyx.git (push)
```

### Working with multiple remotes

```bash
git fetch --all                  # fetch from every remote at once
git push origin main              # push to one specific remote
git push backup main               # push the same branch to a different remote
git push upstream main             # push to yet another (if you have access)
```

You can also push to **multiple remotes with one command** by adding extra push URLs to a single remote name:

```bash
git remote set-url --add --push origin https://github.com/AlirezaAkhavanJava/webflyx.git
git remote set-url --add --push origin git@gitlab.com:AlirezaAkhavanJava/webflyx.git
git push origin main    # pushes to BOTH URLs now
```

---

## 5. "Local Remote" — What This Actually Means

This phrase usually refers to one of two things:

### A) A remote pointing to a **local filesystem path** (no network/server involved)

```bash
git remote add local-backup /mnt/hdd/backups/webflyx.git
git push local-backup main
```

Useful for a quick local backup repo, or for testing push/pull workflows without needing GitHub at all. The path just needs to be a valid Git repository (usually a **bare repo** — see below).

### B) The distinction between "remote-tracking branch" (often just called "the local copy of the remote's state") vs the actual server

This is the `origin/main` concept from earlier — a **local**, read-only reflection of the remote's last-known state, stored in your own `.git/refs/remotes/`. Some people loosely call this "the local remote" since it lives on your machine but represents remote data.

---

## 6. Bare Repositories (relevant for local/backup remotes)

A **bare repo** has no working directory — just the `.git` internals, meant purely to be pushed to/fetched from, not edited directly:

```bash
git init --bare /mnt/hdd/backups/webflyx.git
git remote add backup /mnt/hdd/backups/webflyx.git
git push backup main
```

This is exactly how GitHub/GitLab store your repos server-side — every remote you push to is, on their end, a bare repo.

---

## Full Command Reference for Remote Management

|Command|What it does|
|---|---|
|`git remote -v`|List all remotes with URLs|
|`git remote add <name> <url>`|Add a new remote|
|`git remote remove <name>`|Remove a remote|
|`git remote rename <old> <new>`|Rename a remote|
|`git remote set-url <name> <url>`|Change a remote's URL|
|`git remote set-url --add --push <name> <url>`|Add an _additional_ push destination to an existing remote|
|`git fetch --all`|Fetch from every remote|
|`git push <remote> <branch>`|Push to a specific remote|
|`git branch -vv`|See which remote each local branch tracks|
|`git init --bare <path>`|Create a bare repo (for use as a remote target)|

---

**One-line definitions to remember:**

> **`origin`** = your primary remote, usually where you cloned from or where you push your work.  
> **`upstream`** = the original project you forked from, used to stay in sync — you pull from it, rarely push to it.  
> **Multiple remotes** are fully supported and common — same repo can sync to GitHub, GitLab, and a local backup simultaneously.  
> **Local remote** = a remote whose URL is just a filesystem path instead of a server address — often a bare repo used for backups or testing.




[[0 - Git 🍋‍🟩]]