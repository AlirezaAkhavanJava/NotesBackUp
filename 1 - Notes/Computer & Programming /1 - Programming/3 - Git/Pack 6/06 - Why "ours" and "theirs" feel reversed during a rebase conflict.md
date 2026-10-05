


Let's build the mental model.

The confusion comes from this:

> In a normal merge, **ours = your current branch** and **theirs = the branch you are merging in**.  
> In a rebase, Git temporarily changes what your "current branch" is, because it is replaying your commits onto another branch.

During rebase, Git's point of view changes.

---

# 1. Normal merge: the intuitive case

Imagine:

```text
main

A---B---C---D
        \
         feature
```

You are on:

```bash
git switch main
```

Then:

```bash
git merge feature
```

Git says:

```
ours = main
theirs = feature
```

Because:

```
HEAD = main
incoming branch = feature
```

Conflict:

```java
<<<<<<< HEAD
// ours
return users;
=======
// theirs
return activeUsers;
>>>>>>> feature
```

This makes sense.

---

# 2. Now rebase changes the story

Your history:

```text
main

A---B---C---D---E
             \
              fix_bug
```

Actually:

```text
             fix_bug
                |
                v

A---B---C---F---G
            |
           main
```

You run:

```bash
git switch fix_bug
git rebase main
```

Your intention:

> "Take my commits and put them after main."

Git internally does:

## Step 1

Move to `main`:

```text
A---B---C---F---G
                |
               HEAD
```

## Step 2

Replay your commits:

```text
A---B---C---F---G---D'
```

The important part:

While replaying `D`, Git is **not currently sitting on your old branch**.

It is sitting on the new base.

---

# 3. What does HEAD mean during rebase?

During a rebase conflict:

```java
<<<<<<< HEAD
return verifiedUsers();
=======
return activeUsers();
>>>>>>> D123abc
```

People expect:

```
HEAD = my branch
```

But during rebase:

```
HEAD = the branch you are rebasing onto
```

Usually:

```
HEAD = main
```

So:

```java
<<<<<<< HEAD
```

means:

> "The current state after applying main."

Not:

> "Your original branch."

---

# 4. Why does Git call your commit "theirs"?

Because internally, rebase is similar to:

```
checkout main
apply my commit
```

The operation looks like:

```
Current state:
        main
         |
         v

A---B---C---M


Apply:
        D
```

Git sees:

```
ours:
    current checked-out state (main)

theirs:
    commit being replayed (your old commit)
```

So:

```
ours = main
theirs = your commit
```

That is why it feels backwards.

---

# 5. Example

Before:

Your branch:

```java
// fix_bug
return userRepository.findActiveUsers();
```

Main:

```java
// main
return userRepository.findVerifiedUsers();
```

During rebase:

```bash
git rebase main
```

Conflict:

```java
<<<<<<< HEAD
return userRepository.findVerifiedUsers();
=======
return userRepository.findActiveUsers();
>>>>>>> abc123
```

Meaning:

```
HEAD
 |
 +-- main version


abc123
 |
 +-- your old commit
```

So:

|Git term|During rebase|
|---|---|
|ours|the new base (`main`)|
|theirs|commit being replayed (`fix_bug`)|

---

# 6. The dangerous part: `git checkout --ours`

This creates mistakes.

During merge:

```bash
git checkout --ours UserService.java
```

means:

> Keep my current branch.

During rebase:

```bash
git checkout --ours UserService.java
```

means:

> Keep the new base (`main`).

Not your feature branch.

---

Example:

Conflict:

```java
<<<<<<< HEAD
main code
=======
my feature code
>>>>>>> commit123
```

Run:

```bash
git checkout --ours UserService.java
```

Result:

```java
main code
```

You just discarded your rebased commit.

---

# 7. During rebase, if you want your changes

Use:

```bash
git checkout --theirs UserService.java
```

because:

```
theirs = commit being replayed
```

Result:

```java
my feature code
```

---

# 8. Better mental model

Do not memorize:

```
ours = me
theirs = them
```

That is the source of confusion.

Instead ask:

> "What is Git considering the current operation?"

---

## Merge

Operation:

```
I am merging another branch into my branch
```

Therefore:

```
ours = current branch
theirs = incoming branch
```

---

## Rebase

Operation:

```
I am replaying my commits onto another branch
```

Therefore:

```
ours = new base
theirs = commit being replayed
```

---

# Final mental model

```
MERGE:

          ours
           |
           v

A---B---C---M
         \
          D
          ^
          |
       theirs


REBASE:

new base
   |
   v

A---B---C---M---D'
              ^
              |
           theirs
        (commit replay)
```

The professional rule:

> During a rebase conflict, never think "ours means my code". Think "ours means the current base Git is building on; theirs means the commit Git is trying to replay."


[[Git & Github]]