

The first thing to understand is that Git does **not** fundamentally think in terms of "folders containing branches."

Git fundamentally stores **commits**, and branches are movable **references pointing to commits**.

Think:

```text
                    branch
                      │
                      ▼
A ─────── B ─────── C
                  ↑
                 HEAD
```

Here:

- `A`, `B`, `C` = commits
    
- `main` = a reference pointing to `C`
    
- `HEAD` = tells Git what you currently have checked out
    
- `C` = the commit currently checked out
    

---

# 1. What is a Git commit?

A commit is a snapshot of your project plus metadata.

For example:

```text
A
│
├── README.md
├── pom.xml
└── src/
```

Then you modify something and commit:

```text
A ─── B
```

Then another change:

```text
A ─── B ─── C
```

Each commit has a unique hash:

```text
A = 7a91f2...
B = c83d10...
C = e912ab...
```

Git identifies commits using these hashes.

---

# 2. What is a branch?

A branch is essentially a **movable pointer to a commit**.

Suppose:

```text
A ─── B ─── C
          ↑
         main
```

`main` is not a copy of your project.

It is essentially:

```text
main → C
```

When you create another branch:

```bash
git branch feature
```

you get:

```text
             feature
                ↓
A ─── B ─── C
                ↑
               main
```

Both branches currently point to the same commit.

Then you make a commit while on `feature`:

```text
             feature
                ↓
A ─── B ─── C ─── D
                ↑
               main
```

Actually, after the new commit:

```text
             feature
                ↓
A ─── B ─── C ─── D
                ↑
               main
```

`main` stays at `C`.

`feature` moves to `D`.

This is the key idea:

> **A branch moves forward when you create commits on it.**

---

# 3. What is HEAD?

`HEAD` tells Git:

> **"Where am I currently checked out?"**

Normally `HEAD` points to a branch.

```text
HEAD
 │
 ▼
main
 │
 ▼
C
```

So:

```text
HEAD → main → C
```

If you switch to `feature`:

```bash
git switch feature
```

you get:

```text
HEAD
 │
 ▼
feature
 │
 ▼
D
```

So:

```text
HEAD → feature → D
```

### Therefore

Don't think:

> HEAD = current branch

Think:

> **HEAD points to the current branch.**

And:

> **The current branch points to the current commit.**

---

# 4. How to inspect HEAD

Run:

```bash
git symbolic-ref HEAD
```

Output:

```text
refs/heads/main
```

This means:

```text
HEAD
 ↓
refs/heads/main
```

You can also use:

```bash
git branch --show-current
```

Output:

```text
main
```

Or:

```bash
git status
```

Output:

```text
On branch main
nothing to commit, working tree clean
```

---

# 5. Your `.git/refs/` example

You showed:

```text
.git/refs/
├── heads/
│   └── main
├── remotes/
│   └── origin/
│       ├── Sample
│       └── main
└── tags/
```

This is extremely useful.

Let's decode it.

## `.git/refs/heads/`

```text
.git/refs/heads/main
```

This represents your **local branch**:

```text
main
```

Conceptually:

```text
refs/heads/main → commit
```

---

# 6. `.git/refs/remotes/`

You have:

```text
.git/refs/remotes/origin/main
.git/refs/remotes/origin/Sample
```

These are **remote-tracking references**.

Conceptually:

```text
origin/main
origin/Sample
```

They tell your local Git repository:

> "This is where these branches on the remote were last known to be."

---

# 7. What is `origin`?

This distinction is important.

`origin` is **not a special type of branch**.

It's a **remote name**.

For example:

```bash
git remote -v
```

might give:

```text
origin  https://github.com/example/webflyx.git (fetch)
origin  https://github.com/example/webflyx.git (push)
```

Think:

```text
origin
   │
   └──────► GitHub repository
```

You can actually have multiple remotes:

```text
origin
upstream
company
```

`origin` is simply the conventional default name Git gives the remote when you clone a repository.

---

# 8. Local branch vs remote-tracking branch

This is probably the most important distinction for what you were asking earlier.

You have:

```text
main
```

and:

```text
origin/main
```

They are **not the same thing**.

### Local branch

```text
main
```

Stored conceptually under:

```text
refs/heads/main
```

### Remote-tracking branch

```text
origin/main
```

Stored conceptually under:

```text
refs/remotes/origin/main
```

Visualize:

```text
LOCAL REPOSITORY

refs/heads/
    │
    └── main
          ↓
        commit C


refs/remotes/
    │
    └── origin/
          ├── main
          │    ↓
          │  commit C
          │
          └── Sample
               ↓
             commit X
```

---

# 9. Your `Sample` branch

You currently have:

```text
origin/Sample
```

but apparently not:

```text
Sample
```

Therefore:

```bash
git branch
```

shows:

```text
* main
```

while:

```bash
git branch -r
```

shows:

```text
origin/Sample
origin/main
```

This means:

> Your local repository knows about a remote branch called `Sample`, but you haven't created a local `Sample` branch.

---

# 10. How to create the local branch

Use:

```bash
git switch --track origin/Sample
```

Now:

```text
origin/Sample
       ↑
       │ tracks
       │
     Sample
       ↑
      HEAD
```

More precisely:

```text
HEAD
 ↓
Sample
 ↓
commit X

Sample ───────► origin/Sample
```

`Sample` is now a local branch whose **upstream branch** is `origin/Sample`.

---

# 11. What does "tracking" mean?

Suppose:

```text
Sample → commit X
origin/Sample → commit X
```

Your local `Sample` branch is configured to track `origin/Sample`.

Git can therefore tell you:

```text
Your branch is ahead of 'origin/Sample' by 2 commits.
```

or:

```text
Your branch is behind 'origin/Sample' by 3 commits.
```

This is called the **upstream branch**.

Check it with:

```bash
git branch -vv
```

Example:

```text
* Sample abc1234 [origin/Sample] Add authentication
  main   def5678 [origin/main] Initial project
```

Read this as:

```text
Sample
  ↓
currently at abc1234
  ↓
tracking origin/Sample
  ↓
commit message = Add authentication
```

---

# 12. `git branch -vv` is extremely useful

Example:

```text
* main   91ab23c [origin/main] Add README
  Sample 7fd321a [origin/Sample] Add database
```

Interpretation:

|Output|Meaning|
|---|---|
|`*`|current branch|
|`main`|local branch|
|`91ab23c`|current commit|
|`[origin/main]`|upstream branch|
|`Add README`|latest commit message|

If you see:

```text
[origin/main: ahead 2]
```

your local branch has 2 commits that aren't represented by the remote-tracking reference.

If:

```text
[origin/main: behind 3]
```

the remote-tracking reference has 3 commits that your local branch doesn't have.

---

# 13. Remote-tracking branches aren't automatically updated

This is another important concept.

Suppose GitHub has:

```text
main → D
```

Your local repository currently knows:

```text
origin/main → C
```

Someone pushes `D` to GitHub.

Your local `origin/main` doesn't magically change.

You need:

```bash
git fetch origin
```

Then:

```text
GitHub:

main → D

       fetch

Local:

origin/main → D
```

`git fetch` updates your remote-tracking references.

---

# 14. `fetch` vs `pull`

This distinction is fundamental.

### `git fetch`

Downloads remote changes and updates your remote-tracking references.

```text
remote
   ↓
fetch
   ↓
origin/main
```

It does **not normally modify your current local branch**.

---

### `git pull`

Conceptually:

```text
git pull
=
git fetch
+
git merge
```

Depending on configuration, pull can also use rebase.

For example:

```text
git pull --rebase
```

means roughly:

```text
fetch
+
rebase
```

---

# 15. `push`

Push goes the opposite direction:

```text
local branch
     │
     │ git push
     ▼
remote repository
```

Example:

```bash
git push origin main
```

Read this as:

> Push my local `main` branch to the `origin` remote.

---

# Branch command table

Here is the practical branching command set.

|Command|Purpose|
|---|---|
|`git branch`|List local branches|
|`git branch -a`|List local + remote-tracking branches|
|`git branch -r`|List remote-tracking branches|
|`git branch -v`|Show branches + latest commit|
|`git branch -vv`|Show branches + upstream/tracking information|
|`git branch --show-current`|Show current branch|
|`git branch NAME`|Create a branch|
|`git branch -d NAME`|Delete merged local branch|
|`git branch -D NAME`|Force-delete local branch|
|`git branch -m NEW`|Rename current branch|
|`git branch -m OLD NEW`|Rename branch|
|`git switch NAME`|Switch branches|
|`git switch -c NAME`|Create + switch to branch|
|`git switch -C NAME`|Create/reset + switch to branch|
|`git switch --track origin/NAME`|Create local tracking branch|
|`git checkout NAME`|Older way to switch branches|
|`git checkout -b NAME`|Older way to create + switch|
|`git merge NAME`|Merge branch into current branch|
|`git rebase NAME`|Rebase current branch onto another|
|`git branch --merged`|Show branches merged into current branch|
|`git branch --no-merged`|Show branches not merged into current branch|

---

# Remote commands

These are closely related.

|Command|Meaning|
|---|---|
|`git remote`|List remote names|
|`git remote -v`|Show remote names + URLs|
|`git remote show origin`|Detailed information about `origin`|
|`git remote add NAME URL`|Add a remote|
|`git remote remove NAME`|Remove a remote|
|`git fetch origin`|Fetch from `origin`|
|`git fetch --all`|Fetch all remotes|
|`git push origin main`|Push `main` to `origin`|
|`git push -u origin main`|Push + establish upstream|
|`git push -u origin Sample`|Push Sample + establish upstream|
|`git push --delete origin Sample`|Delete remote branch|

---

# 16. The `-u` option

This is extremely useful.

Suppose you create:

```bash
git switch -c feature
```

Then:

```bash
git push -u origin feature
```

The first push does two things:

```text
local feature
      │
      ├── push ──► origin/feature
      │
      └── tracking relationship established
```

Afterward, you can often simply do:

```bash
git push
```

instead of:

```bash
git push origin feature
```

because Git knows:

```text
feature → origin/feature
```

---

# 17. How to read `git status`

Example:

```text
On branch main
Your branch is ahead of 'origin/main' by 2 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
```

Read it piece by piece.

### `On branch main`

```text
HEAD → main
```

You're currently on `main`.

### `ahead ... by 2 commits`

```text
main
 ↓
A ─ B ─ C ─ D
            ↑
         origin/main
```

Actually, if local is ahead:

```text
origin/main
     ↓
A ─── B ─── C ─── D
                    ↑
                  main
                  HEAD
```

You have two commits that haven't been pushed.

### `working tree clean`

Your working directory has no uncommitted changes.

---

# 18. Common problem: "Why doesn't `git branch` show Sample?"

You run:

```bash
git branch
```

and get:

```text
* main
```

But:

```bash
git branch -r
```

gives:

```text
origin/Sample
origin/main
```

### Problem

`Sample` is remote-tracking only.

### Solution

```bash
git switch --track origin/Sample
```

Now:

```bash
git branch
```

gives:

```text
* Sample
  main
```

---

# 19. Common problem: "I created a branch but GitHub doesn't show it"

You run:

```bash
git switch -c feature
```

Then:

```bash
git branch
```

shows:

```text
* feature
  main
```

But GitHub doesn't show `feature`.

That's because:

> **Creating a local branch does not create a remote branch.**

You need:

```bash
git push -u origin feature
```

Then:

```text
local feature
      │
      │ push
      ▼
origin/feature
      │
      ▼
GitHub feature
```

---

# 20. Common problem: "I deleted my local branch but GitHub still has it"

You run:

```bash
git branch -d feature
```

That deletes:

```text
local feature
```

It does **not** necessarily delete:

```text
GitHub feature
```

To delete the remote branch:

```bash
git push origin --delete feature
```

Then fetch/prune if necessary:

```bash
git fetch --prune
```

---

# 21. Common problem: "Why is my branch behind?"

You see:

```text
Your branch is behind 'origin/main' by 3 commits.
```

Meaning:

```text
origin/main
      ↓
A ─ B ─ C ─ D
      ↑
    main
```

The remote-tracking branch has commits your local branch doesn't.

You can integrate them with:

```bash
git pull
```

or explicitly:

```bash
git fetch origin
git merge origin/main
```

or:

```bash
git fetch origin
git rebase origin/main
```

Which strategy you use depends on your project's workflow.

---

# 22. Common problem: "Why does `origin/main` exist when I never created it?"

Because when you clone:

```bash
git clone URL
```

Git normally creates:

```text
origin
```

as the remote.

Then it fetches the remote branches and creates remote-tracking references such as:

```text
origin/main
origin/develop
origin/Sample
```

These are your local knowledge of the remote repository.

---

# 23. `origin/main` does NOT mean "remote branch object"

This subtle distinction is worth remembering.

Suppose GitHub contains:

```text
main → commit ABC
```

Your local Git has:

```text
origin/main → commit ABC
```

`origin/main` is a **local remote-tracking reference**.

It represents the state of the remote branch as last observed by your local repository.

After:

```bash
git fetch origin
```

it gets updated.

---

# 24. The complete architecture

This is the mental model I want you to remember:

```text
                    REMOTE REPOSITORY
                    ┌───────────────┐
                    │    GitHub     │
                    │               │
                    │ main ───► D   │
                    │ Sample ─► X   │
                    └───────┬───────┘
                            │
                         fetch
                            │
                            ▼
              YOUR LOCAL REPOSITORY
              
       .git/refs/remotes/origin/
              │
              ├── main ─────► D
              │
              └── Sample ───► X
              
       .git/refs/heads/
              │
              ├── main ─────► C
              │
              └── Sample ───► X
```

And:

```text
HEAD
 │
 ▼
Sample
 │
 ▼
X
```

So there are **three different concepts**:

### 1. Local branch

```text
Sample
```

Your branch.

### 2. Remote-tracking branch

```text
origin/Sample
```

Your local reference representing what Git last saw on the remote.

### 3. Actual remote repository branch

```text
GitHub's Sample
```

The branch that actually exists on the remote server.

---

# 25. Detached HEAD

Normally:

```text
HEAD → main → C
```

But you can directly checkout a commit:

```bash
git switch --detach C
```

Now:

```text
HEAD
 ↓
 C

main ───► C
```

HEAD isn't pointing to a branch.

That's:

> **Detached HEAD state.**

`git status` might say:

```text
HEAD detached at C
```

You can inspect old commits safely, but if you create commits there without creating a branch, they aren't attached to a normal branch reference.

To preserve your work:

```bash
git switch -c my-work
```

---

# 26. Commands I recommend you memorize first

Don't try to memorize 50 commands immediately.

Master these:

```bash
git branch
git branch -r
git branch -a
git branch -vv

git switch main
git switch -c feature
git switch --track origin/feature

git status
git log --oneline --graph --decorate --all

git fetch origin
git pull
git push
git push -u origin feature

git merge feature
git rebase main
```

Especially this one:

```bash
git log --oneline --graph --decorate --all
```

It gives you a visual representation of the repository:

```text
* 91ab23c (HEAD -> feature, origin/feature) Add API
* 73de821 Add service
| * 44cd123 (origin/main, main) Update README
|/
* 1234567 Initial commit
```

Read it as:

```text
HEAD
 ↓
feature
 ↓
91ab23c

origin/feature
 ↓
91ab23c

main
 ↓
44cd123

origin/main
 ↓
44cd123
```

Once you can read that output, **Git branching becomes dramatically easier to reason about**.

[[0 - Git 🍋‍🟩]]