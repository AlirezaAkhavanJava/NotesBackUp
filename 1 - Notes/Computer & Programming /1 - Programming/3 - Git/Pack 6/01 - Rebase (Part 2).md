
In the "real world," what happens most often is:

1. You switch to a new branch, say `fix_bug`, which is a copy of `main`.
2. While you're fixing the bug, someone else merges _their_ changes into `main`.
3. You fix the bug, and it so happens that you edited the same files (and lines) that the other person did.
4. You open a Pull Request to merge (or rebase) `fix_bug` into `main`, then Git tells you there's a conflict.
5. You resolve the conflict on your branch.
6. You complete the Pull Request with the conflict resolved.

---
This is one of the most important Git concepts: **why conflicts happen and where they are resolved**.

Let's build the mental model.

---

# 1. Starting point: `fix_bug` is created from `main`

Imagine the repository:

```
main

A---B---C
```

`C` is the latest commit.

You create a branch:

```bash
git switch -c fix_bug
```

Now both branches point to the same commit:

```
          fix_bug
             |
A---B---C
             |
            main
```

At this moment they are identical.

---

# 2. You start fixing the bug

You edit:

```
UserService.java
```

Maybe this line:

```java
return userRepository.findAll();
```

You change it:

```java
return userRepository.findActiveUsers();
```

Commit:

```bash
git add .
git commit -m "fix user filtering bug"
```

Now:

```
          fix_bug
             |
A---B---C---D
             |
            main
```

Your branch has a new commit `D`.

---

# 3. Someone else changes `main`

Another developer is working from `main`.

They edit the same file:

```
UserService.java
```

They change the same line:

Before:

```java
return userRepository.findAll();
```

Their change:

```java
return userRepository.findVerifiedUsers();
```

They commit:

```
          fix_bug
             |
A---B---C---D


A---B---C---E
             |
            main
```

Now the branches have diverged.

Git sees:

```
Common ancestor:
        C

Your change:
        D

Their change:
        E
```

---

# 4. Why does Git have a conflict?

Git tries to combine:

```
       D
      /
C
      \
       E
```

It asks:

> "The original line was this. Both people changed it. Which version should survive?"

Original:

```java
return userRepository.findAll();
```

Your version:

```java
return userRepository.findActiveUsers();
```

Their version:

```java
return userRepository.findVerifiedUsers();
```

Git cannot know your intention.

Maybe:

- `findActiveUsers()` is correct
    
- `findVerifiedUsers()` is correct
    
- both are needed:
    

```java
return userRepository.findActiveVerifiedUsers();
```

Only a human understands the business logic.

---

# 5. Opening the Pull Request

You push:

```bash
git push origin fix_bug
```

Then create:

```
fix_bug  --->  main
```

GitHub checks:

```
Can I merge D into main?
```

It tries:

```
C + D + E
```

but gets:

```
CONFLICT
```

The PR says:

```
This branch has conflicts that must be resolved
```

---

# 6. Where do you resolve the conflict?

The important idea:

> You do not usually fix the conflict directly on GitHub. You bring `main` into your branch, resolve locally, then push.

You are on:

```
fix_bug
```

Run:

```bash
git fetch origin
git merge origin/main
```

or:

```bash
git rebase origin/main
```

Now Git attempts:

```
origin/main

A---B---C---E
             \
              D?
```

and stops:

```
CONFLICT (content): Merge conflict in UserService.java
```

---

# 7. What does the file look like?

Git marks the conflict:

```java
<<<<<<< HEAD
return userRepository.findVerifiedUsers();
=======
return userRepository.findActiveUsers();
>>>>>>> fix_bug
```

Meaning:

```
<<<<<<< HEAD
```

Your current branch version.

```
=======
```

separator.

```
>>>>>>> fix_bug
```

The incoming change.

You decide:

Example:

```java
return userRepository.findActiveVerifiedUsers();
```

Remove the markers.

---

# 8. Tell Git the conflict is fixed

```bash
git add UserService.java
```

Then:

For merge:

```bash
git commit
```

For rebase:

```bash
git rebase --continue
```

---

# 9. Update the Pull Request

Push again:

```bash
git push
```

Now GitHub sees:

```
main

A---B---C---E


fix_bug

A---B---C---E---D'
```

The conflict is gone.

The PR can merge.

---

# Merge vs Rebase conflict resolution

## Merge approach

You do:

```bash
git merge main
```

Result:

```
      D
     /
A---B---C---E---M
     \       /
      -------
```

Creates a merge commit `M`.

---

## Rebase approach

You do:

```bash
git rebase main
```

Result:

```
A---B---C---E---D'
```

Your commit is recreated on top of the latest main.

---

# The key mental model

A Git conflict is **not a Git failure**.

It means:

> "Two histories changed the same thing, and Git needs a human decision."

The workflow is:

```
Create branch
      |
      v
Work independently
      |
      v
main changes
      |
      v
Branches diverge
      |
      v
Merge/Rebase detects conflict
      |
      v
Human chooses correct code
      |
      v
Commit resolved result
      |
      v
Merge completed
```

A professional developer sees conflicts as normal synchronization points between parallel histories.


[[Git & Github]]