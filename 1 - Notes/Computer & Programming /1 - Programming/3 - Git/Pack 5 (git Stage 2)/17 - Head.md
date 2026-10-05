


> **`HEAD` points to the commit that your current checkout is based on. Usually, that is the latest commit of the current branch.**

For a normal branch checkout:

```text
main
  ↓
  C3
  ↑
 HEAD
```

You can see it with:

```bash
git log --oneline -1
```

or:

```bash
git rev-parse HEAD
```

### Why "usually"?

Because `HEAD` does **not actually point to a branch**.

Normally:

```text
HEAD → main → C3
```

So `HEAD` indirectly points to the latest commit of `main`.

If you switch branches:

```bash
git switch feature
```

then:

```text
HEAD → feature → C7
```

Now `HEAD` refers to `C7`.

### Detached HEAD

You can also have:

```text
HEAD → C3
```

with no branch involved:

```bash
git checkout <commit>
```

This is called **detached HEAD**.

So the most accurate definition is:

> **`HEAD` is Git's symbolic reference to your current checkout. When you're on a branch, `HEAD` normally points to that branch, and the branch points to its latest commit.**

This distinction becomes **very important for `HEAD~1`, `HEAD^`, reset, restore, rebase, and merge conflicts.**


[[Git & Github]]