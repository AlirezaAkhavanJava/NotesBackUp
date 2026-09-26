

**Divergent branches are two Git branches that have developed different commits after sharing a common ancestor.**

In simple terms:

> **The branches started from the same commit, then each branch moved forward independently.**

Example:

```text
        A
        │
        B
       / \
      C   D
      │   │
      E   F
      │   │
   main  feature
```

Here:

- `B` is the **common ancestor**.
    
- `main` continued with `C → E`.
    
- `feature` continued with `D → F`.
    
- Therefore, `main` and `feature` have **diverged**.
    

### Mental model

Imagine a road splitting:

```text
                 C ── E   ← main
                /
A ── B ───────
                \
                 D ── F   ← feature
```

At `B`, there was one history.

After `B`, there are **two independent histories**.

That's divergence.

---

### Why does Git care?

Suppose you have:

```text
main:    A ── B ── C
                    \
feature:             D ── E
```

If you now want to combine them, Git needs to reconcile the two histories.

You can use:

```bash
git merge feature
```

which produces something like:

```text
A ── B ── C ───── M
          \      /
           D ── E
```

Or you can use:

```bash
git rebase main
```

which rewrites the feature branch so its commits come after `main`:

```text
A ── B ── C ── D' ── E'
```

### Important distinction

**Divergence does not mean there is a conflict.**

You can have divergent branches with **zero conflicts**:

```text
main:    A ── B ── C
              \
feature:       D
```

Git can merge them automatically.

A **merge conflict** happens when Git cannot automatically reconcile the changes—often because both branches modified overlapping parts of the same file.

So:

```text
Divergence
    ↓
Different histories
    ↓
Need to integrate histories
    ↓
Merge / Rebase
    ↓
May or may not produce conflicts
```

**One-line definition:**

> **Divergent branches are branches that share a common ancestor but have accumulated different commits since branching from that ancestor.**


---

To **solve divergent branches**, you need to decide which history you want to keep and then **integrate the two branches**.

The two standard solutions are **merge** and **rebase**.

### 1. Merge — preserve both histories

Suppose:

```text
        C ── D   ← main
       /
A ── B
       \
        E ── F   ← feature
```

Switch to the branch that should receive the changes:

```bash
git switch main
```

Then:

```bash
git merge feature
```

Git creates a merge commit:

```text
        C ── D ───── M   ← main
       /            /
A ── B              /
       \            /
        E ── F ────
```

**Use merge when:** you want to preserve the actual branching history.

---

### 2. Rebase — make the history linear

Starting with:

```text
        C ── D   ← main
       /
A ── B
       \
        E ── F   ← feature
```

Run:

```bash
git switch feature
git rebase main
```

Git takes `E` and `F` and reapplies them on top of `D`:

```text
A ── B ── C ── D ── E' ── F'   ← feature
```

The commits become `E'` and `F'` because they're **new commits with new identities**.

Then you can merge the now-linear feature branch:

```bash
git switch main
git merge feature
```

Result:

```text
A ── B ── C ── D ── E' ── F'   ← main
```

---

## If Git says "divergent branches"

You may see something like:

```text
hint: You have divergent branches and need to specify how to reconcile them.
```

You can explicitly choose:

### Merge

```bash
git pull --no-rebase
```

### Rebase

```bash
git pull --rebase
```

Or configure your preference permanently:

```bash
git config --global pull.rebase true
```

or:

```bash
git config --global pull.rebase false
```

---

## What I recommend understanding first

Don't think:

> "Divergence = error."

Think:

```text
Divergence
    │
    ├── Merge  → preserve both histories
    │
    └── Rebase → replay your commits on top of the other branch
```

**Divergence itself isn't a problem.** It's Git telling you:

> "These two histories moved independently. Tell me how you want them integrated."

And one very important rule:

> **Don't blindly use `git reset --hard` to "fix" divergence.** Reset changes where your branch points and can discard local work.




[[0 - Git 🍋‍🟩]]