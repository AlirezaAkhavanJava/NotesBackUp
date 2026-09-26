
### Definition

**`git diff` shows the differences between two states of your Git repository.**

Simply:

> **`git diff` = show me what changed.**

It is mainly used to inspect changes **before committing them**.

---

## 1. Basic `git diff`

```bash
git diff
```

Shows changes between:

```text
Last commit (HEAD)
       ↓
Working directory
```

Example:

You changed:

```java
return "Hello";
```

to:

```java
return "Hello World";
```

`git diff` might show:

```diff
- return "Hello";
+ return "Hello World";
```

`-` = removed  
`+` = added

---

# 2. Git has 3 important states

This is where `git diff` becomes much easier to understand:

```text
             git add
Working ─────────────────→ Staging
   │                          │
   │                          │ git commit
   ↓                          ↓
                  Repository (HEAD)
```

There are therefore **two major diffs** you should know.

### Working directory vs Staging

```bash
git diff
```

Means:

> "What have I changed but **not staged** yet?"

---

### Staging vs HEAD

```bash
git diff --staged
```

Means:

> "What have I staged that is **not committed yet**?"

You can also write:

```bash
git diff --cached
```

Same thing.

---

# 3. Example workflow

Suppose you modify:

```text
User.java
```

Then:

```bash
git diff
```

shows:

```text
HEAD
 ↓
old version
     ↕
working directory
new version
```

Then:

```bash
git add User.java
```

Now:

```bash
git diff
```

shows nothing, because the changes are staged.

But:

```bash
git diff --staged
```

shows your changes:

```text
HEAD
 ↓
old version
     ↕
staging area
new version
```

Then:

```bash
git commit
```

The difference disappears because the change is now part of `HEAD`.

---

# 4. Compare two commits

You can compare any two commits:

```bash
git diff abc123 def456
```

Meaning:

> Show me the differences between commit `abc123` and commit `def456`.

You can also use relative references:

```bash
git diff HEAD~2 HEAD
```

Meaning:

> Compare the commit from 2 commits ago with the current commit.

---

# 5. Compare a specific file

```bash
git diff User.java
```

Only shows changes to `User.java`.

And:

```bash
git diff --staged User.java
```

shows the staged changes to that file.

---

## The mental model

Remember these three commands:

```bash
git diff
```

**Working → Staging**

```bash
git diff --staged
```

**Staging → HEAD**

```bash
git diff HEAD
```

**Working + Staging → HEAD**

So the easiest definition to remember is:

> **`git diff` lets you inspect what changed between Git states.**


[[0 - Git 🍋‍🟩]]