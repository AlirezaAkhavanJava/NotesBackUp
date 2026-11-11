

A **merge conflict** happens when Git tries to combine two branches, but it cannot automatically decide which changes should remain.

The core problem:

> Two different commits modified the same part of a file, and Git needs a human decision.

Git is good at combining changes. It is not good at understanding **intent**.

---

# 1. Simple example

Start:

```
main
 |
 A
 |
 B
 |
 C
```

You create a branch:

```bash
git switch -c feature
```

Now:

```
          feature
             |
A---B---C
             |
            main
```

Both branches are identical.

---

# 2. Two developers edit the same line

## Developer 1 (feature branch)

Original:

```java
String message = "Hello";
```

Changes it:

```java
String message = "Hello User";
```

Commit:

```
D
```

History:

```
          feature
             |
A---B---C---D
             |
            main
```

---

## Developer 2 (main branch)

Meanwhile, they edit the same line:

Original:

```java
String message = "Hello";
```

Changes it:

```java
String message = "Hello World";
```

Commit:

```
E
```

History:

```
          feature
             |
A---B---C---D


A---B---C---E
             |
            main
```

Now the branches have diverged.

---

# 3. Git tries to merge

You run:

```bash
git switch main
git merge feature
```

Git compares:

```
        D (your change)
       /
A---B---C
       \
        E (their change)
```

Git sees:

Original:

```java
String message = "Hello";
```

Change 1:

```java
String message = "Hello User";
```

Change 2:

```java
String message = "Hello World";
```

Question:

> Which one should I keep?

Git cannot answer.

So:

```
CONFLICT (content): Merge conflict
```

---

# 4. How Git shows a conflict

The file becomes:

```java
<<<<<<< HEAD
String message = "Hello World";
=======
String message = "Hello User";
>>>>>>> feature
```

Meaning:

```
<<<<<<< HEAD
```

Your current branch version.

---

```
=======
```

The dividing line.

---

```
>>>>>>> feature
```

The incoming branch version.

---

# 5. You resolve it manually

You decide:

```java
String message = "Hello World User";
```

You remove:

```text
<<<<<<<
=======
>>>>>>>
```

Now the file is normal again.

---

# 6. Tell Git the conflict is solved

Check:

```bash
git status
```

Example:

```
both modified: Message.java
```

Stage the resolved file:

```bash
git add Message.java
```

Complete the merge:

```bash
git commit
```

Git creates a merge commit:

```
        D
       / \
A---B---C---M
       \ /
        E
```

`M` means:

> "I combined these two histories."

---

# Types of merge conflicts

## 1. Same line conflict

Most common.

Example:

Both edit:

```java
int maxUsers = 100;
```

Developer A:

```java
int maxUsers = 200;
```

Developer B:

```java
int maxUsers = 500;
```

Git cannot choose.

---

## 2. Same file, different lines

Usually Git can handle this.

Example:

Developer A edits line 10:

```java
username validation
```

Developer B edits line 200:

```java
password hashing
```

Git automatically combines them.

No conflict.

---

## 3. File deleted vs modified

Developer A:

```
delete User.java
```

Developer B:

```
modify User.java
```

Git asks:

> Should the file exist or be deleted?

---

## 4. Rename conflict

Developer A:

```
User.java → Account.java
```

Developer B:

```
User.java → Customer.java
```

Git needs a decision.

---

# Useful conflict commands

## See conflicts

```bash
git status
```

---

## See only conflicted files

```bash
git diff --name-only --diff-filter=U
```

---

## Abort merge

If you want to undo the merge attempt:

```bash
git merge --abort
```

Returns to:

```
before merge started
```

---

## Continue after fixing

```bash
git add .
git commit
```

---

# Conflict resolution mindset

Do not think:

> "Which code should I keep?"

Think:

> "What is the correct final state of the program?"

Sometimes:

Keep yours:

```java
ours
```

Sometimes:

Keep theirs:

```java
theirs
```

Sometimes:

Combine both:

```java
new solution
```

The conflict is not about Git. It is about **two different versions of reality needing reconciliation**.


[[Git & Github]]