 This is one of the small Git details that becomes very important once you use `git worktree`.

## 1. The thing you're trying to determine

Suppose you run:

```bash
git branch
```

and see:

```text
* main
  add_customers
  fix_bug
  experiment
```

The `*` means:

> **`main` is the branch currently checked out in my current worktree.**

But what about another worktree?

Git marks that differently.

---

## 2. Create a second worktree

Imagine:

```bash
git worktree add ../megacorp-fix fix_bug
```

Now you have:

```text
megacorp/       → main
megacorp-fix/   → fix_bug
```

From the original `megacorp` worktree:

```bash
git branch
```

you'll see something like:

```text
* main
+ fix_bug
  experiment
  add_customers
```

The important symbol is:

```text
+
```

### `+` means:

> **This branch is checked out in another worktree.**

So:

```text
* main       ← checked out HERE
+ fix_bug    ← checked out in ANOTHER worktree
  experiment ← not checked out
```

---

# 3. Why does Git do this?

Because Git needs to prevent you from accidentally checking out the same branch in two worktrees.

For example:

```text
Worktree A
    ↓
main

Worktree B
    ↓
fix_bug
```

If you're inside Worktree A and try:

```bash
git switch fix_bug
```

Git knows:

```text
"Wait — fix_bug is already checked out somewhere else."
```

and normally refuses:

```text
fatal: 'fix_bug' is already used by worktree at '...'
```

The `+` in `git branch` gives you a quick visual indication of that state.

---

# 4. The authoritative command

Although `git branch` shows the `+`, the better command for inspecting worktrees is:

```bash
git worktree list
```

For example:

```text
/mnt/hdd/.../megacorp       b6c5f1b [main]
/mnt/hdd/.../megacorp-fix   30f59b3 [fix_bug]
```

Now you know exactly:

```text
Directory              Branch
───────────────────────────────
megacorp               main
megacorp-fix           fix_bug
```

So the mental model is:

```text
git branch
    ↓
quick branch overview
    ↓
* = this worktree
+ = another worktree


git worktree list
    ↓
full worktree → branch mapping
```

---

# 5. One subtle point

The `+` isn't saying:

> "This branch is currently active."

It's saying:

> **"This branch is checked out in another linked worktree."**

That's why these two symbols are useful:

```text
* main
```

means:

```text
main → current worktree
```

while:

```text
+ fix_bug
```

means:

```text
fix_bug → different worktree
```

And:

```text
  experiment
```

means:

```text
experiment → not checked out in a worktree
```

---

## Quick rule to memorize

```text
git branch

*  = checked out HERE
+  = checked out in ANOTHER worktree
   = not checked out
```

Then if you need to know **where** that `+` branch is checked out:

```bash
git worktree list
```

That's the reliable worktree-level view.


[[Git & Github]]