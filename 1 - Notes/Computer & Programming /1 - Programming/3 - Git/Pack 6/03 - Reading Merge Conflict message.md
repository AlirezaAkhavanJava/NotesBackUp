
To read a Git merge conflict message, you need to understand that Git is telling you **three things**:

1. **What operation failed**
    
2. **Which files have conflicts**
    
3. **Where Git needs your decision**
    

Let's use a real example.

---

## 1. The terminal message

You run:

```bash
git merge feature
```

Git says:

```text
Auto-merging UserService.java
CONFLICT (content): Merge conflict in UserService.java
Automatic merge failed; fix conflicts and then commit the result.
```

Read it like this:

---

### `Auto-merging UserService.java`

Git found this file exists in both branches.

It tried:

```
main version
      +
feature version
      =
new combined version
```

---

### `CONFLICT (content)`

This is the important part.

`content` means:

> The actual text inside the file conflicts.

Example:

Both branches changed:

```java
return users;
```

Git cannot decide.

---

### `Merge conflict in UserService.java`

This tells you:

> Open this file. The problem is inside it.

Check:

```bash
git status
```

You will see:

```text
Unmerged paths:

    both modified:   UserService.java
```

Meaning:

```
main changed this file
        +
feature changed this file
        =
Git needs help
```

---

# 2. Reading the conflict markers

Open the file:

```java
<<<<<<< HEAD
return userRepository.findActiveUsers();
=======
return userRepository.findVerifiedUsers();
>>>>>>> feature
```

This is Git's explanation.

---

## `<<<<<<< HEAD`

Meaning:

> "This is the version from the branch you are currently on."

Example:

You are currently on:

```bash
main
```

So:

```java
<<<<<<< HEAD
```

means:

```
main's code
```

---

## `=======`

Separator:

```
YOUR VERSION
============
THEIR VERSION
```

---

## `>>>>>>> feature`

Meaning:

> "This is the incoming branch's version."

Example:

```text
>>>>>>> feature
```

means:

```
feature branch's code
```

---

# 3. Visual interpretation

Git is showing:

```
             merge
               |
               v

             HEAD
              |
              |
<<<<<<< HEAD
main code
              |
==============
              |
feature code
              |
>>>>>>> feature
```

---

# 4. How Git thinks about it

Imagine history:

```
          feature
             |
A---B---C---D


A---B---C---E
             |
            main
```

Common ancestor:

```
C
```

Your branch changed:

```
C → D
```

Other branch changed:

```
C → E
```

Git compares:

```
        D
       /
C
       \
        E
```

It asks:

> "C had one thing. D changed it one way. E changed it another way. What should the final code be?"

---

# 5. Conflict types in the message

## Content conflict

Example:

```text
CONFLICT (content): Merge conflict in app.java
```

Meaning:

Same lines changed.

---

## Add/add conflict

Example:

```text
CONFLICT (add/add): Merge conflict in config.yml
```

Meaning:

Both branches created a file with the same name.

Example:

```
main:
+ config.yml


feature:
+ config.yml
```

Git asks:

Which file is correct?

---

## Modify/delete conflict

Example:

```text
CONFLICT (modify/delete)
```

Meaning:

One branch changed a file:

```
modify User.java
```

Another deleted it:

```
delete User.java
```

---

# 6. The correct workflow after seeing a conflict

First:

```bash
git status
```

Find files:

```
both modified: UserService.java
```

Open:

```bash
nvim UserService.java
```

Find:

```
<<<<<<<
=======
>>>>>>>
```

Decide the final code.

Then:

```bash
git add UserService.java
```

Complete:

For merge:

```bash
git commit
```

For rebase:

```bash
git rebase --continue
```

---

# Professional mental model

When you see:

```
CONFLICT
```

translate it to:

> "Git successfully found the battlefield. It failed only at the decision point. I need to choose the final code."

Git is not broken. The repository is waiting for a human judgment.


[[Git & Github]]