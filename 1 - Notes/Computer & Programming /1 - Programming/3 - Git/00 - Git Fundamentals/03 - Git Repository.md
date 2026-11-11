A **Git repository** (or "repo") is a project folder that Git is watching, together with a hidden database that remembers every saved version of that project. The files you see and edit are only the current snapshot. The full history lives next to them, inside a folder named `.git`.

The key idea is that **every copy of a repo carries the whole history**. That is why Git is called "distributed". You can commit, browse history, and branch with no internet at all, and any clone can rebuild the project if the server disappears.

## The big picture: three places a change lives

Your files move through three areas on their way into history:

```
Working directory  --git add-->  Staging area (index)  --git commit-->  Repository (.git)
   (your files)                   (next snapshot)                         (saved history)
```

|Area|What it is|Where it physically is|
|---|---|---|
|**Working directory**|The files you edit|The normal project folder|
|**Staging area**|The list of changes going into the _next_ commit|A file: `.git/index`|
|**Repository**|Committed snapshots, branches, tags|`.git/objects`, `.git/refs`|

The staging area lets you build a commit deliberately. You can edit five files and commit only two of them.

Every file is in one of four states:

|State|Meaning|Move it on with|
|---|---|---|
|Untracked|Git has never seen it|`git add`|
|Modified|Tracked, changed, not staged|`git add`|
|Staged|Will be in the next commit|`git commit`|
|Committed|Safe in history||

## What's inside `.git/`

```
.git/
├── HEAD        → "ref: refs/heads/main" (which branch you're on)
├── config      → settings for this repo only
├── index       → the staging area
├── objects/    → all content: files (blobs), folders (trees), commits
├── refs/
│   ├── heads/    → your branches
│   ├── tags/     → your tags
│   └── remotes/  → what Git last saw on each remote
├── logs/       → the reflog (where branches used to point)
└── hooks/      → optional automation scripts
```

A branch is just a small file in `refs/heads/` holding a commit hash. That is why creating a branch is instant. `HEAD` points at the branch you're on. This is the same model you saw in the plumbing lesson, where `update-ref` writes one of these files.

## The three kinds of repository

|Kind|What it is|Create it with|
|---|---|---|
|**Local**|Normal repo on your machine, with working files|`git init` or `git clone`|
|**Remote**|A copy hosted elsewhere (GitHub, GitLab, a server) that people share|Created on the host|
|**Bare**|History only, no working files. Used as a shared hub|`git init --bare` or `git clone --bare`|

A fix to the original note: a bare repo is not a folder containing `.git/`. Its top level **is** the contents of `.git/` (`HEAD`, `objects/`, `refs/`, and so on). Bare repos are named like `project.git`. You can't edit files in one, which is exactly why servers use them: nobody's uncommitted work can collide with a push.

## Core operations

|Goal|Command|
|---|---|
|Start a new repo|`git init`|
|Copy an existing one|`git clone <url>`|
|See what changed|`git status`|
|Stage|`git add <file>`|
|Save|`git commit -m "message"`|
|Share|`git push`|
|Get updates|`git pull` (or `git fetch` to look first)|
|New branch and switch to it|`git switch -c feature`|
|Switch to an existing branch|`git switch main`|

`git branch feature` only creates a branch and does not switch to it. The old `git checkout <name>` still works, but `switch` is clearer.

## Remotes

A **remote** is a saved nickname for a URL. `origin` is the name Git gives the repo you cloned from.

```bash
git remote -v                                  # list remotes
git remote add upstream https://github.com/org/repo.git
git remote set-url origin git@github.com:you/repo.git
```

### Pushing to two places

The original note suggests `git config --add remote.origin.url ...`. That works, but it behaves oddly: **fetch uses only the first URL, while push goes to all of them**. The clearer way is to add a second _push_ URL:

```bash
git remote set-url --add --push origin https://gitlab.com/user/repo.git
```

Note that once you set any push URL, you must add the original one as a push URL too, or it will be skipped.

## Repo-only configuration

Settings in `.git/config` apply to this repo and override your global ones:

```bash
git config --local user.email "project@example.com"
git config --local --list
```

## See it for yourself

```bash
git init demo && cd demo
ls -a                              # you'll see .git
echo "hi" > a.txt
git add a.txt
git commit -m "first"
cat .git/HEAD                      # ref: refs/heads/main
cat .git/refs/heads/main           # a commit hash
git cat-file -p HEAD               # the commit's contents
```

On Windows PowerShell, use `dir -Force` instead of `ls -a`, and `type` instead of `cat`.

## Rules to remember

- Don't edit `.git/` by hand. Use Git commands.
- Deleting `.git/` deletes the history but leaves your files. The folder turns back into a plain folder.
- Pushing regularly is your backup. A repo on one disk is still just one disk.
- Use `git status` constantly. It tells you which area every change is in.



[[Git & Github]]