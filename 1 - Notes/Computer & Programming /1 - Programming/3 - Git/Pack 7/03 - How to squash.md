
In Git, **squashing** means taking multiple commits and combining them into **one commit**.

The most common way is **interactive rebase**.

### Example

Suppose your history is:

```text
A -- B -- C -- D -- E   (HEAD)
```

You want to turn `C`, `D`, and `E` into one commit:

```text
A -- B -- X   (HEAD)
```

### 1. Start interactive rebase

```bash
git rebase -i HEAD~3
```

Git opens something like:

```text
pick abc123 C: add login
pick def456 D: fix login
pick ghi789 E: style login
```

Keep the first commit as `pick`, and change the others to `squash`:

```text
pick abc123 C: add login
squash def456 D: fix login
squash ghi789 E: style login
```

Save and exit.

Git then combines the commits and asks you to edit the resulting commit message.

For example:

```text
C: add login
D: fix login
E: style login
```

You can replace it with:

```text
Add login functionality
```

Now:

```text
A -- B -- Add login functionality
```

---

### `squash` vs `fixup`

You can also use:

```text
pick abc123 C: add login
fixup def456 D: typo
fixup ghi789 E: formatting
```

The difference:

- `squash` → combines commits **and lets you edit their commit messages**
    
- `fixup` → combines commits and **discards the later commit messages**
    

For cleanup commits, `fixup` is usually what you want.

---

### If you want to squash the last 5 commits

```bash
git rebase -i HEAD~5
```

Then:

```text
pick   oldest
squash second
squash third
squash fourth
squash newest
```

Result:

```text
before:

A -- B -- C -- D -- E -- F

after:

A -- X
```

where `X` contains the changes from `B` through `F`.

### Important

Rebase **rewrites commit history**. If these commits have already been pushed to a shared branch, be careful.

If you have already pushed your branch and then squash it:

```bash
git push --force-with-lease
```

Prefer `--force-with-lease` over `--force` because it provides a safety check.

**Mental model:**

```text
squash = "Take these several snapshots of my work and rewrite them as one snapshot/commit."
```

And importantly, **squashing changes the commit history, not the final files**.



[[Git & Github]]