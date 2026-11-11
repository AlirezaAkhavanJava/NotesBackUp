`git diff` is one of the most important Git commands because it answers a very specific question:

> **"What exactly changed?"**

## 1. Definition

`git diff` **compares two states of your project and shows the line-by-line differences between them.**

It doesn't change anything.

```bash
git diff
```

is purely a **read/inspection operation**.

---

# 2. The important Git states

To understand `diff`, you need to understand that Git doesn't just have "your code."

There are three important states:

```text
                git add
Working Tree ──────────────> Staging Area
     │                            │
     │                            │ git commit
     │                            ↓
     └──────────────────────> Repository
```

Example:

```text
Working Tree
    ↓
    your actual files

Staging Area
    ↓
    what will go into the next commit

Repository
    ↓
    committed history
```

`git diff` lets you compare these states.

---

# 3. `git diff`

Suppose:

```text
README.md
```

originally contains:

```text
Hello
Java
Git
```

You edit it:

```text
Hello
Java
Git
Linux
```

Now:

```bash
git diff
```

shows:

```diff
 Hello
 Java
 Git
+Linux
```

`+` means **added**.

If you removed something:

```diff
 Hello
 Java
-Git
```

`-` means **removed**.

---

# 4. What does plain `git diff` compare?

This is extremely important.

```bash
git diff
```

means:

> **Working Tree ↔ Staging Area**

In other words:

> "What have I changed that I have NOT staged yet?"

Example:

```bash
vim App.java
```

You modify it.

```bash
git diff
```

shows your unstaged changes.

Then:

```bash
git add App.java
```

Now:

```bash
git diff
```

shows **nothing**.

Why?

Because your change moved from:

```text
Working Tree
      ↓ git add
Staging Area
```

There is no longer a difference between them.

---

# 5. Then how do I see staged changes?

Use:

```bash
git diff --staged
```

or:

```bash
git diff --cached
```

These are equivalent.

It means:

> **Staging Area ↔ Last Commit**

Example:

```text
Repository
    │
    │ git add
    ↓
Staging Area
```

You can inspect exactly what you're about to commit:

```bash
git diff --staged
```

This is a **very important professional workflow**:

```bash
git add App.java

git diff --staged

git commit -m "Add user validation"
```

You're essentially checking:

> "Is the thing I'm about to commit actually what I intended?"

---

# 6. The three useful commands

Memorize these:

```bash
git diff
```

**Unstaged changes**

```bash
git diff --staged
```

**Staged changes**

```bash
git diff HEAD
```

**Everything changed since the last commit**

Think:

```text
                 HEAD
                  │
                  │
              Repository
                  │
             ┌────┴────┐
             ↓         ↓
         Staging    Working
          Area       Tree

git diff
    ↑
Working Tree ↔ Staging Area

git diff --staged
    ↑
Staging Area ↔ HEAD

git diff HEAD
    ↑
Working Tree + Staging Area ↔ HEAD
```

---

# 7. Comparing commits

`git diff` isn't limited to your current changes.

You can compare commits:

```bash
git diff abc123 def456
```

Meaning:

> "Show me what changed between commit `abc123` and commit `def456`."

Example:

```text
A --- B --- C --- D
    ↑           ↑
  old commit  new commit
```

```bash
git diff B D
```

shows everything that changed between B and D.

---

# 8. Comparing a commit with your current state

You can also do:

```bash
git diff HEAD
```

or:

```bash
git diff HEAD~1
```

For example:

```bash
git diff HEAD~1 HEAD
```

means:

> "Show me exactly what changed in the most recent commit."

This is extremely useful when investigating history.

---

# 9. `diff` vs `revert` vs `reset`

These commands have completely different jobs:

|Command|Purpose|
|---|---|
|`git diff`|**Inspect** changes|
|`git revert`|**Undo** a commit by creating another commit|
|`git reset`|**Move** the branch/HEAD|
|`git restore`|**Discard/restore file changes**|

So:

```text
git diff
    ↓
"What changed?"

git revert
    ↓
"Undo that committed change while preserving history."

git reset
    ↓
"Move my branch back."

git restore
    ↓
"Throw away/restore changes in files."
```

### The mental model

Whenever you're confused about your Git state, `git diff` is one of your first weapons:

```bash
git status
git diff
git diff --staged
```

Those three commands tell you **where your changes are and what they actually contain**.

[[Git & Github]]