# Rebase Conflict in Git

A **rebase conflict** happens when Git tries to **replay your commits on top of another branch**, but one of your commits changes the same code that was changed in the target branch.

The difference from a merge conflict:

- **Merge conflict:** Git combines two histories.
    
- **Rebase conflict:** Git is replaying your commits one by one and one of them cannot be applied.
    

---

# 1. Starting situation

You have:

```text
main

A---B---C
```

You create a branch:

```bash
git switch -c feature
```

Now:

```text
        feature
           |
A---B---C
           |
          main
```

---

# 2. You create commits

You make two commits:

### Commit D

```java
// UserService.java
return users;
```

changes to:

```java
return activeUsers;
```

Commit:

```text
D: fix user filtering
```

---

### Commit E

You add another feature:

```java
log.info("loading users");
```

Commit:

```text
E: add logging
```

History:

```text
             feature
                |
A---B---C---D---E
                |
               main
```

---

# 3. Main changes while you work

Another developer updates `main`:

```text
main

A---B---C---F
```

Their commit `F` changes the same line that your commit `D` changed.

Now:

```text
                 feature
                    |
A---B---C---D---E


A---B---C---F
             |
            main
```

Branches diverged.

---

# 4. You start rebase

You want your feature on the latest main:

```bash
git switch feature
git rebase main
```

Git thinks:

> "Move feature commits on top of main."

Before:

```text
             D---E
            /
A---B---C---F
```

Actually it does:

1. Move feature pointer to `main`
    
2. Replay `D`
    
3. Replay `E`
    

Like this:

```text
A---B---C---F
             \
              D'
              E'
```

---

# 5. The conflict happens

Git tries:

```
Apply commit D
```

But `D` changes a line that `F` already changed.

Git stops:

```text
CONFLICT (content): Merge conflict in UserService.java
error: could not apply D... fix user filtering
```

Read this as:

```
CONFLICT
    |
    v
Git failed while applying commit D

Commit:
D: fix user filtering

File:
UserService.java
```

---

# 6. Check the situation

Run:

```bash
git status
```

You see:

```text
interactive rebase in progress

You are currently rebasing branch 'feature'

Unmerged paths:

    both modified: UserService.java
```

Important phrase:

```
currently rebasing
```

means:

> Git has paused the rebase and is waiting for you.

---

# 7. The conflict markers during rebase

Open the file:

```java
<<<<<<< HEAD
return verifiedUsers;
=======
return activeUsers;
>>>>>>> D
```

During rebase, the meaning is slightly different.

## `HEAD`

During rebase:

```text
HEAD = the new base (main)
```

So:

```java
<<<<<<< HEAD
```

means:

> Code currently in `main`.

---

## The bottom part

```java
>>>>>>> D
```

means:

> The commit Git is trying to replay.

Example:

```
main version
     |
     v
<<<<<<< HEAD
return verifiedUsers;
=======
return activeUsers;
>>>>>>> D
```

Meaning:

```
main changed it to verifiedUsers

your old commit D wants activeUsers
```

---

# 8. Resolve it

Choose the correct final code:

```java
return activeVerifiedUsers;
```

Remove markers.

Then:

```bash
git add UserService.java
```

Continue:

```bash
git rebase --continue
```

Git now tries the next commit:

```
Apply E
```

If no conflict:

```
Successfully rebased and updated refs/heads/feature.
```

---

# 9. Abandon the rebase

If things become confusing:

```bash
git rebase --abort
```

Git returns to the state before:

```bash
git rebase main
```

Your branch goes back:

Before:

```text
A---B---C---D---E
```

After abort:

```text
A---B---C---D---E
```

---

# 10. Merge conflict vs Rebase conflict

## Merge

Command:

```bash
git merge main
```

Git creates:

```text
       D
      / \
A---B---C---M
      \ /
       F
```

Conflict happens while combining histories.

---

## Rebase

Command:

```bash
git rebase main
```

Git creates:

```text
A---B---C---F---D'---E'
```

Conflict happens while replaying commits.

---

# The most important rebase conflict skill

When Git says:

```text
error: could not apply abc123... commit message
```

Read it as:

> "I was replaying this specific commit. That commit could not be applied. Fix the file, stage it, then continue."

The workflow:

```bash
git status

# edit conflicted files

git add <file>

git rebase --continue
```

or escape:

```bash
git rebase --abort
```

A rebase conflict is basically Git saying:

> "I can move your history forward, but this commit needs a human translation into the new world."



[[Git & Github]]