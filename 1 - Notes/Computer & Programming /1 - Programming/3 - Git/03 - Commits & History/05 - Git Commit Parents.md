

# Git Commit Parents, `HEAD~n`, and Merge Commits

## 1. First: what is a commit?

A Git commit is a snapshot of your project plus metadata.

But an important fact is often overlooked:

> **A commit also stores references to its parent commit(s).**

A normal commit has **one parent**.

```text
A → B → C
```

Meaning:

```text
B.parent = A
C.parent = B
```

So if you're currently at `C`:

```text
HEAD
 ↓
 C
 ↓
 B
 ↓
 A
```

You can move backward:

```bash
HEAD~1
```

→ `B`

```bash
HEAD~2
```

→ `A`

---

# 2. What is `HEAD`?

Suppose:

```text
A → B → C
         ↑
        main
         ↑
        HEAD
```

There are actually two references involved:

```text
HEAD → main → C
```

So:

- `HEAD` = what you're currently checked out
    
- `main` = current branch
    
- `C` = branch's latest commit
    

You can verify:

```bash
git log --oneline -1
```

and:

```bash
git rev-parse HEAD
```

---

# 3. Now introduce branching

Suppose:

```text
A → B → C        main
     \
      D → E      feature
```

`main` points to `C`:

```text
main → C
```

`feature` points to `E`:

```text
feature → E
```

If you're on `feature`:

```text
HEAD → feature → E
```

The history from `E` is:

```text
E
↓
D
↓
B
↓
A
```

Therefore:

```bash
HEAD~1  # D
HEAD~2  # B
HEAD~3  # A
```

Notice something important:

`HEAD~` follows **parent relationships**, not the visual position of commits on your terminal.

---

# 4. Merge creates something special

Now suppose `main` and `feature` diverge:

```text
       C → D       main
      /
A → B
      \
       E → F       feature
```

You merge `feature` into `main`.

Git creates a **merge commit**:

```text
       C → D ────┐
      /          │
A → B            M
      \          │
       E → F ────┘
```

`M` is different from ordinary commits.

It has **two parents**:

```text
M
├── parent 1 → D
└── parent 2 → F
```

This is the crucial concept.

---

# 5. A merge commit has parent 1 and parent 2

Git records something conceptually like:

```text
commit M
parent D
parent F
```

So:

```text
M^1 → D
M^2 → F
```

You can inspect this with:

```bash
git show --no-patch --pretty=raw M
```

Or for your current commit:

```bash
git show --no-patch --pretty=raw HEAD
```

You'll see multiple `parent` lines for a merge commit.

---

# 6. `^` means "parent"

This notation is extremely important.

```bash
HEAD^
```

means:

> First parent of `HEAD`.

Equivalent to:

```bash
HEAD^1
```

For a merge:

```text
       D
      /
     M
      \
       F
```

you have:

```bash
HEAD^1
```

→ `D`

and:

```bash
HEAD^2
```

→ `F`

---

# 7. `~` means "follow the first parent repeatedly"

This is where your confusion came from.

```bash
HEAD~1
```

means:

> Follow the first parent once.

```bash
HEAD~2
```

means:

> Follow the first parent twice.

```bash
HEAD~3
```

means:

> Follow the first parent three times.

For a merge:

```text
       D
      /
     M
      \
       F
```

we get:

```text
M~1 → D
M~2 → parent of D
M~3 → parent of D's parent
```

It does **not** mean "go to whichever commit looks one position backward."

---

# 8. Apply this to YOUR repository

Your graph was:

```text
*   f43fc4e  HEAD -> add_customers
|\
| * 3ec5254  main
* | d999ac9  C
|/
* afd5c0c     B
* 9f8c24c
* 0d16f95
```

The important part is:

```text
       d999ac9
      /
f43fc4e
      \
       3ec5254
```

So:

```text
f43fc4e
├── parent 1 = d999ac9
└── parent 2 = 3ec5254
```

Therefore:

```bash
HEAD^1
```

is:

```text
d999ac9
```

and:

```bash
HEAD^2
```

is:

```text
3ec5254
```

And:

```bash
HEAD~1
```

also gives:

```text
d999ac9
```

because `~` follows the first parent.

---

# 9. This explains your `reset`

You executed:

```bash
git reset --hard HEAD~1
```

Your starting position:

```text
HEAD
 ↓
f43fc4e
├────→ d999ac9
└────→ 3ec5254
```

`HEAD~1` says:

```text
"Follow the first parent."
```

Therefore:

```text
HEAD
 ↓
d999ac9
```

It didn't skip two commits.

You moved **one parent relationship**.

---

# 10. Why does the graph look like it moved two?

Because you're looking at the graph visually:

```text
*   f43fc4e
|\
| * 3ec5254
* | d999ac9
|/
```

Your eyes might interpret this as:

```text
f43fc4e
 ↓
3ec5254
 ↓
d999ac9
```

But that's **not the history relationship**.

The actual relationships are:

```text
        f43fc4e
        /     \
       ↓       ↓
  d999ac9   3ec5254
```

`3ec5254` and `d999ac9` are **siblings in the parent relationship**.

They are both parents of `f43fc4e`.

---

# 11. A useful mental model

Think of commits as objects with pointers.

Normal commit:

```text
C
│
└── parent → B
```

Merge commit:

```text
M
├── parent 1 → C
└── parent 2 → F
```

Then Git notation becomes intuitive:

### Parent selector

```bash
M^1
```

```text
M → C
```

### Second parent

```bash
M^2
```

```text
M → F
```

### First-parent traversal

```bash
M~1
```

```text
M → C
```

### Continue first-parent traversal

```bash
M~2
```

```text
M → C → B
```

---

# 12. `~` vs `^`

This distinction is worth memorizing:

|Syntax|Meaning|
|---|---|
|`HEAD^`|First parent|
|`HEAD^1`|First parent|
|`HEAD^2`|Second parent|
|`HEAD~1`|First parent, 1 generation back|
|`HEAD~2`|First-parent chain, 2 generations|
|`HEAD~3`|First-parent chain, 3 generations|

For ordinary commits, you won't notice much difference because they only have one parent.

For merge commits, the difference becomes critical.

---

# 13. See it yourself in your repository

Run:

```bash
git show --no-patch --pretty=raw f43fc4e
```

You'll see something conceptually like:

```text
commit f43fc4e
tree ...
parent d999ac9
parent 3ec5254
author ...
committer ...
```

Now:

```bash
git rev-parse f43fc4e^1
```

→

```text
d999ac9
```

And:

```bash
git rev-parse f43fc4e^2
```

→

```text
3ec5254
```

Then:

```bash
git rev-parse f43fc4e~1
```

→

```text
d999ac9
```

That's the relationship Git is using.

---

# 14. Why this matters professionally

Once you understand this, several Git commands become much easier to understand:

```bash
git reset HEAD~1
git reset HEAD^
git reset HEAD^2
git diff HEAD~1
git diff HEAD^1 HEAD^2
git show HEAD^
git log HEAD~5
git rebase HEAD~3
```

And especially:

```bash
git log --first-parent
```

This is very useful for looking at the **mainline history** of a project while treating merged feature branches as branches off that mainline.

---

## The core idea to remember

Don't think:

> "`HEAD~1` means the commit visually one line above/below HEAD."

Think:

> **Git commits form a directed graph. `HEAD~1` follows the first-parent pointer once.**

For a normal commit:

```text
A → B → C
        ↑
       HEAD

HEAD~1 → B
```

For a merge commit:

```text
       B
      ↗
A → M
      ↘
       C

HEAD = M

HEAD^1 → B
HEAD^2 → C
HEAD~1 → B
```

**That's the fundamental model.** Once you see Git as a commit graph rather than a list of commits, merge history, reset, rebase, and `HEAD` notation become much easier.


[[Git & Github]]