
**Git** is a **version control system**: a tool that records every change to your project over time, so you can see what changed, who changed it, why, and go back to any earlier state. It is distributed: every developer has a full copy of the entire history on their own machine.

**Analogy:** A video game with unlimited save points. You save a snapshot (a **commit**) whenever things work, you can reload any earlier save, and you can open a parallel timeline (a **branch**) to try something risky without touching your main game. In the real-projects lesson, "version control" was item five on the checklist; this is that item.

## The problem it solves

Without Git you end up with `project_final`, `project_final2`, `project_REALLY_final`. Two people editing the same file overwrite each other, a bug appears and you can't tell which change caused it, and a bad experiment can't be undone. Git solves all of this: full history, safe experiments, and merging of work from many people.

## Git vs GitHub

||Git|GitHub|
|---|---|---|
|**What**|The tool on your machine|A website that hosts Git repositories|
|**Works offline**|Yes|No|
|**Alternatives**|None, it's the standard|GitLab, Bitbucket|

Git is the engine, and GitHub is a shared garage where teams store and review their code. (This is the same Git/GitHub split you'd see in the profile of any developer.)

## Mental model: three areas

This is the single most useful idea in Git.

```
Working directory  --git add-->  Staging area  --git commit-->  Repository
(your files)                     (next snapshot,               (permanent history)
                                  being prepared)
```

- **Working directory:** the files you edit.
- **Staging area (index):** a waiting room where you choose _which_ changes go into the next commit.
- **Repository (`.git` folder):** the permanent history of commits.

The staging area lets you make one clean commit out of a messy afternoon: "these two files are the bug fix; the other file is unrelated, so it goes in a separate commit."

## What a commit really is

A commit is a **full snapshot** of your project (not a diff), plus a message, author, time, and a pointer to its **parent** commit. Each commit gets a unique ID, a hash like `a1b2c3d`. Because each commit points to its parent, history is a chain:

```
A <- B <- C <- D
```

A **branch** is just a movable _label_ pointing at one commit, and **HEAD** is a pointer to "where you are now". That is why branches are so cheap: creating one is writing a tiny pointer, not copying files.

## Getting started on Debian 13

```bash
sudo apt install git
git config --global user.name "Alireza"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

## Everyday workflow

```bash
git init                       # start a repo in the current folder
git status                     # what changed? (use this constantly)
git add src/BookService.java   # stage one file
git add .                      # stage everything
git commit -m "Add book search"
git log --oneline              # short history
git diff                       # unstaged changes
git diff --staged              # staged changes
```

## Branches and merging

```bash
git switch -c feature/search   # create and move to a new branch
# ...edit, add, commit...
git switch main
git merge feature/search       # bring the work into main
git branch -d feature/search   # delete the finished branch
```

```
        E <- F            feature/search
       /      \
A <- B <- C <- D <- G     main (G = merge commit)
```

If two branches changed the **same lines**, Git can't decide and reports a **merge conflict**. It marks the file like this:

```
<<<<<<< HEAD
String title = "Clean Code";
=======
String title = "Clean Code, 2nd ed.";
>>>>>>> feature/search
```

You edit the file to the final version, remove the markers, then `git add` the file and `git commit`. Conflicts are normal, not a failure.

## Working with a remote (GitHub)

```bash
git clone https://github.com/user/repo.git   # copy a repo, with full history
git remote add origin <url>                  # link a local repo to a remote
git push -u origin main                      # upload your commits
git pull                                     # download and merge others' commits
git fetch                                    # download only, don't merge yet
```

**Typical team flow (pull requests):**

1. Create a branch for one feature.
2. Commit and push it.
3. Open a **pull request** on GitHub so teammates review the code.
4. After approval, merge it into `main`.

## Undoing things (what to use when)

|Situation|Command|
|---|---|
|Discard changes in a file (not staged)|`git restore file`|
|Unstage a file|`git restore --staged file`|
|Fix the last commit message (not yet pushed)|`git commit --amend`|
|Undo a commit **safely**, by adding a new opposite commit|`git revert <hash>`|
|Move the branch back, discarding commits (dangerous)|`git reset --hard <hash>`|
|Temporarily shelve work in progress|`git stash` / `git stash pop`|

Git almost never loses committed work. Even after a bad reset, `git reflog` shows where HEAD has been, so you can recover.

## `.gitignore`: what must not be tracked

Create a file named `.gitignore` in the project root:

```
target/
build/
.idea/
*.log
.env
application-local.properties
```

For your Java projects this means: compiled output (`target/` from Maven, `build/` from Gradle), IDE folders, logs, and **secrets**. This ties to the logging and Docker lessons: never commit passwords or API keys.

## Good commit habits

- **Small, focused commits**: one logical change each.
- **Message in the imperative**: "Add book validation", not "added stuff".
- **Commit often, push when it works.**
- **Never commit secrets**, large binaries, or generated files.
- Use branches for every feature or fix, and keep `main` always working (your tests from the testing lesson are what protect it).

## Gotchas

- **Never rewrite shared history.** `git push --force`, `reset`, and `rebase` on commits others already pulled will break their copies. Rewrite only your own, unpushed work.
- **A secret committed once stays in history,** even if you delete the file in the next commit. You must **revoke the secret** (change the password or key) and treat it as leaked. Deleting the file is not enough.
- **`git add .` can stage things you didn't intend** (secrets, big files). Check `git status` first.
- **Commit vs push:** a commit is local only. Nothing reaches GitHub until you `git push`, so a dead laptop loses unpushed work.
- **Detached HEAD:** checking out a specific commit (not a branch) puts you in this state. Commits made there belong to no branch, so create a branch (`git switch -c name`) before continuing.
- **Merge vs rebase:** `merge` preserves history as it happened; `rebase` replays your commits on top of another branch for a straight, tidy line. Rebase is powerful but rewrites commits, so use it only on local work.
- **Empty folders aren't tracked:** Git tracks files, not directories. Add a placeholder file like `.gitkeep`.
- **Line endings and case sensitivity** can cause trouble when moving between Windows and Linux; Debian is case-sensitive, Windows is not.
- **Git is not a backup by itself.** Unpushed or only-local repositories die with the disk; pushing to a remote helps, but still keep real backups for important data.
- **Learn the command line first.** GUI tools and IDE integrations (IntelliJ has an excellent one) are convenient, but they all just run these same commands, so understanding the commands lets you fix problems when the GUI confuses you.





[[Data-base]]
[[Java]]
[[C]]
[[Python]]
[[Java-Script]]
[[Computer & Programming]]