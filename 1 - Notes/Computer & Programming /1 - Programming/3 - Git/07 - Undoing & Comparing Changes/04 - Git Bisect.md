


## 1. Definition

**`git bisect` is a Git debugging tool that uses binary search to find the commit that introduced a bug.**

The key idea:

> **You know a commit that works and a commit that is broken. Git repeatedly tests the middle of that range until it finds the first bad commit.**

This is incredibly useful when you have hundreds of commits and have no idea which one caused the problem.

---

# 2. The problem it solves

Imagine your history:

```text
A --- B --- C --- D --- E --- F --- G --- H
    GOOD                         ?         BAD
```

You know:

```text
A = works
H = broken
```

But you don't know which commit introduced the bug.

Naively, you could test:

```text
B
C
D
E
F
G
```

That's potentially **6 tests**.

With 1000 commits, that's potentially ~1000 tests.

`git bisect` uses **binary search**.

Instead of checking every commit:

```text
1000 commits
      ↓
     500
      ↓
     250
      ↓
     125
      ↓
      ...
```

You need roughly:

```text
log₂(1000) ≈ 10
```

tests.

That's the real power of `bisect`.

---

# 3. Why does it work?

`bisect` requires an important assumption:

> The bug has a transition point.

Something like:

```text
GOOD GOOD GOOD GOOD BAD BAD BAD BAD
                  ↑
            first bad commit
```

Git doesn't need to understand your bug.

It doesn't know what "broken" means.

**You tell Git whether the commit you're currently testing is good or bad.**

---

# 4. Starting bisect

Suppose:

```text
A --- B --- C --- D --- E --- F --- G
                                  ↑
                               current
                               broken
```

Start:

```bash
git bisect start
```

Tell Git:

```bash
git bisect bad
```

Meaning:

> "The commit I'm currently on is broken."

Then identify a known-good commit:

```bash
git bisect good A
```

Now Git knows:

```text
A = GOOD
G = BAD
```

---

# 5. Git chooses the middle

Git checks out a commit somewhere around the middle:

```text
A --- B --- C --- D --- E --- F --- G
              ↑
           testing
```

Your job is now to test the application.

For example:

```bash
./gradlew test
```

or:

```bash
./gradlew bootRun
```

or manually reproduce the bug.

Then tell Git the result.

### Bug does NOT exist:

```bash
git bisect good
```

### Bug DOES exist:

```bash
git bisect bad
```

Git then chooses another commit.

---

# 6. The algorithm

Imagine:

```text
A --- B --- C --- D --- E --- F --- G --- H
GOOD                                      BAD
```

Git tests `E`.

Suppose:

```text
E = BAD
```

Then the bug must be somewhere between:

```text
A --- B --- C --- D --- E
GOOD                   BAD
```

Everything after E can be ignored.

Git tests the middle again.

Suppose `C` is:

```text
GOOD
```

Now:

```text
A --- B --- C --- D --- E
GOOD        GOOD  ?    BAD
```

The bug must be between C and E.

Eventually:

```text
C --- D --- E
GOOD  BAD   BAD
      ↑
  first bad
```

Git identifies `D`.

---

# 7. Complete workflow

Typical workflow:

```bash
git bisect start
git bisect bad
git bisect good <known-good-commit>
```

Git checks out a commit.

You test it.

If it works:

```bash
git bisect good
```

If it's broken:

```bash
git bisect bad
```

Repeat.

Eventually Git says something like:

```text
<commit> is the first bad commit
```

Then:

```bash
git bisect reset
```

returns you to where you started.

---

# 8. Example with your Java project

Imagine your Spring Boot application worked at:

```text
a1b2c3
```

and is broken at:

```text
f9e8d7
```

Start:

```bash
git bisect start
git bisect bad f9e8d7
git bisect good a1b2c3
```

Git checks out some middle commit:

```text
a1b2c3 --- ... --- c4d5e6 --- ... --- f9e8d7
                         ↑
                      HEAD
```

Run:

```bash
./gradlew test
```

Suppose tests fail.

```bash
git bisect bad
```

Git chooses another commit.

Test again.

```bash
./gradlew test
```

Suppose it passes:

```bash
git bisect good
```

Continue until Git identifies the first bad commit.

---

# 9. The beautiful part: automate it

If you have a command that can reliably tell whether a commit is good or bad, you don't have to manually run:

```bash
git bisect good
git bisect bad
```

You can automate it.

For example:

```bash
git bisect run ./test-script.sh
```

Your script should return:

```text
0     → good
non-zero → bad
```

Example:

```bash
#!/bin/bash

./gradlew test
```

Then:

```bash
git bisect run ./test-script.sh
```

Git will:

```text
checkout commit
      ↓
run test
      ↓
good/bad?
      ↓
choose next commit
      ↓
run test
      ↓
repeat
```

This is where `bisect` becomes extremely powerful.

---

# 10. Important: `bisect` does NOT fix anything

This is another important distinction.

```text
git diff
    ↓
inspect changes

git revert
    ↓
undo a commit

git reset
    ↓
move branch pointer

git cherry-pick
    ↓
apply one commit's changes elsewhere

git bisect
    ↓
FIND which commit caused a problem
```

`bisect` is primarily a **debugging/investigation tool**.

It answers:

> **"Which commit introduced this bug?"**

It does not automatically fix the bug.

---

# 11. The mental model

Imagine your history as:

```text
GOOD                         BAD
  ↓                           ↓
  A --- B --- C --- D --- E --- F --- G
                  ↑
             unknown point
```

`git bisect` repeatedly cuts the search space in half:

```text
A B C D E F G
    ↓
A B C     D E F G
          ↓
A B C D   E
    ↓
A B C D
      ↓
     D = first bad
```

So the one sentence to remember is:

> **`git bisect` uses binary search across your commit history to identify the first commit that introduced a bug.**

And the workflow to memorize is:

```bash
git bisect start
git bisect bad
git bisect good <known-good-commit>

# test
git bisect good   # or bad

# repeat

git bisect reset
```


[[Git & Github]]