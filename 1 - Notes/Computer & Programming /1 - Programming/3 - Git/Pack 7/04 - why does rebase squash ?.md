
Because **squashing is not actually a property of rebase itself**. It's a feature of **interactive rebase**.

The important idea is this:

### What rebase normally does

Suppose you have:

```text
A---B---C---D
        \
         E---F
```

Your branch is based on `C`, and you run:

```bash
git rebase main
```

Git essentially says:

> "Take my commits `E` and `F`, temporarily remove them, move my branch to the new base, then replay `E` and `F`."

Result:

```text
A---B---C---D---E'---F'
```

So **rebase = replay commits onto another base**.

---

### Where does squash come from?

When you run:

```bash
git rebase -i HEAD~3
```

you aren't just saying:

> "Rebase."

You're saying:

> "Rebase these commits **interactively**. Let me tell you what to do with each commit."

Git gives you:

```text
pick   A
pick   B
pick   C
```

`pick` means:

> Replay this commit normally.

But interactive rebase gives you other instructions:

```text
pick
reword
edit
squash
fixup
drop
```

So if you change:

```text
pick A
pick B
pick C
```

to:

```text
pick A
squash B
squash C
```

you're telling Git:

> Replay `A`, then apply `B` and `C` **into the previous commit instead of creating separate commits**.

That's why you get:

```text
Before:

A---B---C

After:

A'
```

---

### The deeper reason this works

Git commits aren't really "changes stored independently."

A commit points to a **snapshot** and its **parent commit**:

```text
A
↓
B
↓
C
```

Think of:

```text
B = parent A + changes_B
C = parent B + changes_C
```

When Git squashes:

```text
A
+
changes_B
+
changes_C
```

it creates a new commit representing the combined result:

```text
A---BC
```

So Git doesn't literally take three existing commit objects and glue them together.

It **reconstructs the history** with a new commit.

That's also why the resulting commit gets a **new SHA-1/SHA-256 object ID**.

---

### So remember this distinction

```text
REBASE
    = move/replay commits onto a different history

INTERACTIVE REBASE
    = manually control how commits are replayed

SQUASH
    = replay a commit's changes into the previous commit
```

That's why `git rebase -i` is such a powerful **history-editing tool**, not merely a "move my branch" command.


[[Git & Github]]