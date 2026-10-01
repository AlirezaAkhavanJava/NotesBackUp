
## Undoing Changes and Managing Uncommitted Work

Sometimes, while working on a feature, we create new files or modify existing ones and later decide that we don't need some of those changes anymore.

Git gives us several tools to safely undo, remove, or temporarily store this work.

---

# 1. Discard changes to an existing file

Suppose we modify:

```text
src/main/java/com/example/UserService.java
```

but decide that we don't want our modifications.

Run:

```bash
git restore src/main/java/com/example/UserService.java
```

This restores the file to the version from the current `HEAD` commit.

For all modified tracked files:

```bash
git restore .
```

### Important

#### `git restore` primarily deals with changes in the **working tree**.

**It does not remove files that have already been staged.**

---

# 2. Remove new untracked files

Suppose we create:

```text
NewService.java
TestService.java
```

but these files have never been committed.

Git considers them **untracked**.

Check:

```bash
git status
```

You might see:

```text
Untracked files:
    NewService.java
    TestService.java
```

To remove untracked files:

```bash
git clean -fd
```

Where:

```text
-f = force
-d = include directories
```

So:

```bash
git clean -fd
```

means:

> Force Git to delete untracked files and directories.

### Preview before deleting

Because `git clean` is destructive, you can first see what would be deleted:

```bash
git clean -fdn
```

`-n` means **dry run**.

This is a good habit.

---

# 3. The staging area changes the situation

A common mistake is forgetting that a file has already been staged.

For example:

```bash
git add .
```

Now:

```bash
git status
```

might show:

```text
Changes to be committed:

    new file: Automation/HabitRule.java
    new file: Automation/HabitRuleEngine.java
```

At this point, running:

```bash
git restore .
```

does **not** undo those staged changes.

Why?

Because Git has three important states:

```text
Working Directory
       ↓
   git add
       ↓
Staging Area
       ↓
  git commit
       ↓
    HEAD
```

`git restore .` restores the **working directory**.

The files are already in the **staging area**, so they remain staged.

---

# 4. Unstage files

If we staged something accidentally:

```bash
git add .
```

we can remove it from the staging area with:

```bash
git restore --staged .
```

Or for one file:

```bash
git restore --staged UserService.java
```

This does **not delete the file**.

It simply moves it from:

```text
Staged
```

back to:

```text
Modified / Untracked
```

depending on the file's state.

---

# 5. Completely discard the work

If your intention is:

> "I don't want any of these changes. Delete them."

A typical cleanup sequence is:

```bash
git restore --staged .
git restore .
git clean -fd
```

Then:

```bash
git status
```

Ideally:

```text
On branch Automation
nothing to commit, working tree clean
```

### What each command does

```bash
git restore --staged .
```

Removes changes from the staging area.

```bash
git restore .
```

Discards modifications to tracked files.

```bash
git clean -fd
```

Deletes untracked files and directories.

Together:

```text
staged changes       → unstaged
unstaged modifications → discarded
untracked files       → deleted
```

Be careful: these operations can destroy work.

---

# 6. Always check before switching branches

Before switching branches, make it a habit to run:

```bash
git status
```

For example:

```bash
git status
```

If you see:

```text
Changes to be committed:
    new file: Automation/HabitRule.java
```

you should decide what to do with it before switching branches.

You have three main choices:

### A. Keep it permanently

Commit it:

```bash
git add .
git commit -m "Add automation engine"
```

### B. Delete it

If you don't need it:

```bash
git restore --staged .
git restore .
git clean -fd
```

### C. Temporarily put it aside

Use:

```bash
git stash
```

This is useful when you aren't finished with the work but need to work on another branch.

---

# 7. Switching branches without taking unfinished work with you

Imagine:

```text
main
  \
   Automation
```

You're currently working on:

```bash
Automation
```

and you have unfinished changes:

```text
Automation:
    HabitRule.java
    HabitRuleEngine.java
    HabitScheduler.java
```

You don't want to commit them yet.

But you need to switch to:

```bash
main
```

You can temporarily store your changes with:

```bash
git stash
```

Then:

```bash
git switch main
```

Now your working directory is clean.

You can work on `main` independently.

---

# 8. Bring your unfinished work back

When you're ready to continue your Automation work:

```bash
git switch Automation
```

Then:

```bash
git stash pop
```

Your unfinished changes will be restored.

The workflow is therefore:

```bash
# Working on feature
git status

# Temporarily store unfinished work
git stash

# Switch branches
git switch main

# Work on main
...

# Return to feature
git switch Automation

# Restore unfinished work
git stash pop
```

---

# 9. `git stash` is basically a temporary shelf

A useful mental model is:

```text
Automation branch

Working directory
       │
       │ git stash
       ▼
   ┌─────────┐
   │  STASH  │
   └─────────┘
       │
       │ git stash pop
       ▼
Working directory
```

The stash is useful when your work is:

- unfinished
    
- not ready for a commit
    
- something you don't want to lose
    
- something you temporarily need to put aside
    

---

# 10. See your stashes

You can see all saved stashes:

```bash
git stash list
```

Example:

```text
stash@{0}: WIP on Automation: 4b51b3d Add automation engine
stash@{1}: WIP on main: 91ac821 Update configuration
```

You can restore a specific stash:

```bash
git stash apply stash@{0}
```

Unlike:

```bash
git stash pop
```

`apply` does **not** remove the stash afterward.

`pop` restores it and then removes it if the operation succeeds.

---

# 11. The safest everyday workflow

Before changing branches, use:

```bash
git status
```

Then choose:

```text
                    git status
                        │
             ┌──────────┴──────────┐
             │                     │
          Changes?              Clean?
             │                     │
       ┌─────┼─────┐               │
       │     │     │               ▼
     Keep  Delete  Later       git switch
       │     │     │
    commit  clean  stash
```

### Keep the work

```bash
git add .
git commit -m "..."
```

### Delete the work

```bash
git restore --staged .
git restore .
git clean -fd
```

### Keep it for later

```bash
git stash
```

Then switch:

```bash
git switch main
```

---

# 12. Important distinction: branch changes vs uncommitted changes

A branch does **not** simply "carry its committed files into another branch."

Suppose:

```text
main
  A---B
       \
        C---D   Automation
```

If `C` and `D` are commits on `Automation`, switching to:

```bash
git switch main
```

does **not** bring commits `C` and `D` into `main`.

`main` remains at:

```text
A---B
```

The confusing situation happens with **uncommitted changes**.

For example:

```text
main
  A---B
       \
        Automation
```

You're on `Automation` and modify:

```text
HabitRule.java
```

but don't commit it.

If Git allows you to switch to `main` while that modification can be carried safely, the modification may still exist in your working directory.

That's why:

```bash
git status
```

is one of the most important commands to run before changing branches.

---

# 13. The core commands

|Command|Purpose|
|---|---|
|`git status`|Inspect current state|
|`git restore <file>`|Discard modifications to a tracked file|
|`git restore .`|Discard tracked modifications|
|`git restore --staged <file>`|Unstage a file|
|`git restore --staged .`|Unstage everything|
|`git clean -fd`|Delete untracked files/directories|
|`git clean -fdn`|Preview what `git clean` would delete|
|`git stash`|Temporarily store changes|
|`git stash list`|Show stashes|
|`git stash pop`|Restore latest stash and remove it|
|`git stash apply`|Restore stash but keep it|
|`git switch main`|Switch to `main`|
|`git switch Automation`|Switch to `Automation`|
|`git add .`|Stage changes|
|`git commit`|Permanently record staged changes|

---

# Mental Model

When you're unsure what to do, think in terms of **three questions**:

### 1. Is it staged?

```bash
git status
```

If yes:

```bash
git restore --staged <file>
```

### 2. Do I want to delete it?

Tracked modification:

```bash
git restore <file>
```

Untracked file:

```bash
git clean -fd
```

### 3. Do I want to keep it for later?

```bash
git stash
```

Then switch branches:

```bash
git switch <branch>
```

This gives you a simple rule:

> **Commit it, delete it, or stash it before changing context.**


[[0 - Git]]