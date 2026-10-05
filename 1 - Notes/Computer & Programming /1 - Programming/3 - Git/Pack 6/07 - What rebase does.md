

You are stuck because the word **"ours" and "theirs" only makes sense after you understand what rebase is actually doing internally**.

Forget conflicts for a moment. First understand **the machine behind rebase**.

---

# 1. The scenario — You are maintaining a feature branch

You work on a Spring Boot project.

You have:

```text
megacorp-api

main
 |
 v

A---B---C
```

`C` is the latest version of the project.

You create:

```bash
git switch -c fix_bug
```

Now:

```text
        fix_bug
           |
           v
A---B---C
           |
           v
          main
```

You start working.

---

# 2. The core mental model

## Rebase is not "moving a branch"

The common beginner explanation:

> "Rebase moves my branch on top of another branch."

It is true, but incomplete.

The real mental model:

> **Rebase takes your commits, creates a temporary copy of them, moves your branch pointer to another place, and then replays your commits one by one.**

Think:

```
old commits
    |
    v
remove temporarily
    |
    v
move branch
    |
    v
apply commits again
```

Your commits are not physically moved.

They are recreated.

---

# 3. You make commits on fix_bug

You edit:

```
UserService.java
```

Original:

```java
public List<User> getUsers() {
    return userRepository.findAll();
}
```

Your fix:

```java
public List<User> getUsers() {
    return userRepository.findActiveUsers();
}
```

Commit:

```bash
git commit -m "fix inactive users"
```

History:

```
        fix_bug
           |
           v

A---B---C---D


main
 |
 v

A---B---C
```

Your commit:

```
D = change findAll() → findActiveUsers()
```

---

# 4. Meanwhile main changes

Another developer updates main.

They also edit:

```
UserService.java
```

They change:

```java
return userRepository.findAll();
```

into:

```java
return userRepository.findVerifiedUsers();
```

Commit:

```
E = verified users
```

Now:

```
        fix_bug

A---B---C---D


A---B---C---E
            |
            v
           main
```

Now the histories are different.

---

# 5. What merge would do

If you did:

```bash
git switch main
git merge fix_bug
```

Git thinks:

"I have two finished histories. Combine them."

Diagram:

```
        D
       /
A---B---C---M
       \
        E
```

Git compares:

```
main version:

findVerifiedUsers()


feature version:

findActiveUsers()
```

Conflict.

Why?

Because Git asks:

> Which final code should exist?

---

# 6. Now rebase

You instead do:

```bash
git switch fix_bug
git rebase main
```

Your goal:

```
I want my bug fix after the newest main.
```

The final result should look like:

```
A---B---C---E---D'
```

Notice:

```
D becomes D'
```

Why?

Because commit D was created when the world looked like:

```
A---B---C
```

Now the world is:

```
A---B---C---E
```

Git must create a new commit that means:

"Apply the same idea, but on this new code."

---

# 7. What Git actually does internally

Your history:

```
A---B---C---D
```

main:

```
A---B---C---E
```

Git does:

## Step 1: Remember your commits

Git says:

```
I need to replay:

D
```

Temporary storage:

```
D
```

---

## Step 2: Move your branch

Your branch moves:

Before:

```
fix_bug
 |
 v

A---B---C---D
```

After:

```
fix_bug
 |
 v

A---B---C---E
```

Your D disappeared temporarily.

---

## Step 3: Apply D again

Git runs something similar to:

```
git apply D
```

Meaning:

"Take the changes introduced by D and put them here."

Now Git tries:

```
A---B---C---E---D'
```

But...

---

# 8. The conflict moment

Commit D says:

"Change this line:"

Before:

```java
return userRepository.findAll();
```

After:

```java
return userRepository.findActiveUsers();
```

But main already changed that line:

```java
return userRepository.findVerifiedUsers();
```

Git sees:

```
Original:

findAll()


main changed:

findVerifiedUsers()


your old commit wants:

findActiveUsers()
```

Git asks:

> "How do I apply this old change to a new version?"

It cannot know.

So:

```
CONFLICT
```

---

# 9. Now the confusing part: ours and theirs

During a normal merge:

You are saying:

> "Combine my branch with another branch."

Example:

```
main (you)
 +
feature (incoming)
```

So:

```
ours = main
theirs = feature
```

Simple.

---

During rebase:

You are saying:

> "Take my old commit and apply it onto another branch."

The operation becomes:

```
Current world:

main


Incoming change:

my old commit
```

Git sees:

```
Current state = ours

Commit being replayed = theirs
```

So:

```
ours = main
theirs = fix_bug commit
```

That is why it feels backwards.

---

# 10. Visualizing rebase conflict

Before rebase:

```
fix_bug

A---B---C---D


main

A---B---C---E
```

During rebase:

Git creates:

```
main

A---B---C---E
             |
             HEAD
```

Then:

```
Apply D
```

Conflict:

```
HEAD
 |
 v

main code


        VS


D
 |
 v

your old commit
```

Therefore:

```
ours
 |
 +-- HEAD (main)


theirs
 |
 +-- commit D (your change)
```

---

# 11. Resolving the conflict

You open:

```
UserService.java
```

You see:

```java
<<<<<<< HEAD
return userRepository.findVerifiedUsers();
=======
return userRepository.findActiveUsers();
>>>>>>> D
```

Meaning:

```
<<<<<<< HEAD

main's current version


=======


your commit being replayed


>>>>>>> D
```

You decide:

Maybe the correct code is:

```java
return userRepository.findActiveVerifiedUsers();
```

Then:

```bash
git add UserService.java
```

Continue:

```bash
git rebase --continue
```

---

# 12. What if you use checkout commands?

This is where people get burned.

During merge:

```bash
git checkout --ours file
```

means:

```
keep my branch
```

During rebase:

```bash
git checkout --ours file
```

means:

```
keep main
```

because main is currently HEAD.

---

# 13. The professional way to think about it

Never memorize:

```
ours = me
theirs = them
```

Instead:

Ask:

> "Who is HEAD right now?"

Because Git defines:

```
ours = HEAD
theirs = incoming change
```

---

# Final mental model

## Merge:

```
             ours
              |
              v

A---B---C---M
     \
      D

theirs
```

You combine two branches.

---

## Rebase:

```
Step 1:

A---B---C---E
        |
       HEAD


Step 2:

Apply old commit D


A---B---C---E---D'
```

You are replaying history.

---

# Flow chart

```
Need latest main
        |
        v
git rebase main
        |
        v
Git moves branch to main
        |
        v
Git replays your commits
        |
        v
Can commit apply?
        |
   +----+----+
   |         |
 Yes        No
   |         |
finish    conflict
             |
             v
       edit files
             |
             v
          git add
             |
             v
    git rebase --continue
             |
             v
          finished
```

The sentence to remember:

> A merge conflict asks "how do I combine two histories?", while a rebase conflict asks "how do I replay this old change onto a new version of the world?"


[[Git & Github]]