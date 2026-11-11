
 Once you understand **creating** and **detecting** worktrees, the next part is managing their lifecycle: **move/change, remove, prune**.

# 1. First: what can you actually "alter"?

A worktree has a few different properties:

```text
Worktree
├── filesystem directory
├── checked-out branch/commit
└── worktree metadata
```

You can:

- change which branch/commit it is on
    
- move the worktree directory
    
- remove the worktree
    
- repair/prune stale worktree metadata
    

The commands are different for each.

---

# 2. Changing the branch of a worktree

Suppose:

```text
megacorp/
    → main

megacorp-fix/
    → fix_bug
```

Go into the second worktree:

```bash
cd ../megacorp-fix
```

Then simply use normal Git commands:

```bash
git switch experiment
```

Now:

```text
megacorp/
    → main

megacorp-fix/
    → experiment
```

The worktree itself hasn't changed. Its **checked-out branch** changed.

Check:

```bash
git branch
```

or:

```bash
git status
```

---

# 3. Can you switch to a branch already used by another worktree?

Normally:

```bash
git switch main
```

will fail if `main` is already checked out somewhere else.

That's intentional.

You should generally have:

```text
Worktree A → main
Worktree B → feature
Worktree C → experiment
```

not:

```text
Worktree A → main
Worktree B → main
```

Git protects you from accidentally having two worktrees modifying the same branch independently.

---

# 4. Moving a worktree

Suppose you have:

```text
../megacorp-fix/
```

and want:

```text
../debug/megacorp-fix/
```

**Don't simply use `mv` as your normal method.**

Use:

```bash
git worktree move ../megacorp-fix ../debug/megacorp-fix
```

Git then updates its worktree metadata correctly.

Check:

```bash
git worktree list
```

You should now see the new location.

---

# 5. Removing a worktree

Suppose:

```text
megacorp-fix/
    → fix_bug
```

and you're finished with it.

From another worktree:

```bash
git worktree remove ../megacorp-fix
```

Git removes that worktree.

Then:

```bash
git worktree list
```

will no longer show it.

### Important

Removing the worktree does **not necessarily delete the branch**.

You can still have:

```text
fix_bug
```

as a branch.

If you also want to delete the branch:

```bash
git branch -d fix_bug
```

So:

```text
git worktree remove
        ↓
delete filesystem checkout

git branch -d
        ↓
delete branch
```

These are separate operations.

---

# 6. What if the worktree has uncommitted changes?

Suppose:

```text
megacorp-fix/
    fix_bug
        │
        └── modified files
```

Git normally protects you from accidentally destroying those changes.

You may get an error when trying:

```bash
git worktree remove ../megacorp-fix
```

You need to decide what to do with the changes first:

```bash
git status
```

Then either:

```bash
git commit
```

or:

```bash
git stash
```

or otherwise intentionally discard them.

There is also:

```bash
git worktree remove --force ../megacorp-fix
```

But **don't use `--force` casually**. It is specifically for intentionally removing a worktree despite protections.

---

# 7. Removing a broken/stale worktree

Here's an important situation.

You create:

```bash
git worktree add ../megacorp-fix fix_bug
```

Then someone manually deletes:

```text
../megacorp-fix/
```

with:

```bash
rm -rf ../megacorp-fix
```

Git may still have metadata saying:

```text
fix_bug → ../megacorp-fix
```

Now you have a **stale worktree entry**.

Check:

```bash
git worktree list
```

Then:

```bash
git worktree prune
```

Git removes stale worktree metadata.

---

# 8. `remove` vs `prune`

This distinction matters.

### `git worktree remove`

You tell Git:

> I am intentionally removing this worktree.

```bash
git worktree remove ../megacorp-fix
```

### `git worktree prune`

You tell Git:

> Clean up worktree metadata for worktrees that no longer exist.

```bash
git worktree prune
```

Mental model:

```text
Normal removal:

git worktree remove
        ↓
Git knows about removal
        ↓
clean state


Manual deletion:

rm -rf worktree
        ↓
Git doesn't know
        ↓
stale metadata
        ↓
git worktree prune
```

---

# 9. Repairing a worktree

There is also:

```bash
git worktree repair
```

This is useful when a worktree's location changed outside Git's knowledge.

For example:

```text
Git thinks:

/old/path/megacorp-fix


But you manually moved it:

/new/path/megacorp-fix
```

You can use:

```bash
git worktree repair
```

from the affected worktree or appropriate repository context to repair the administrative links.

But as a rule:

> **Use `git worktree move` instead of manually moving worktrees.**

That prevents the problem in the first place.

---

# 10. Complete lifecycle

You can think of worktree management like this:

```text
                 CREATE
                   │
                   ▼
          git worktree add
                   │
                   ▼
             USE / SWITCH
                   │
             git switch
                   │
                   ▼
               MOVE
                   │
          git worktree move
                   │
                   ▼
              REMOVE
                   │
         git worktree remove
                   │
                   ▼
               CLEAN UP
                   │
          git worktree prune
```

And inspect everything with:

```bash
git worktree list
```

---

# 11. The commands you should memorize

```bash
# See all worktrees
git worktree list

# Create
git worktree add ../name branch

# Create new branch + worktree
git worktree add -b new_branch ../name

# Move
git worktree move OLD_PATH NEW_PATH

# Remove
git worktree remove PATH

# Remove stale metadata
git worktree prune

# Repair worktree metadata
git worktree repair
```

### One important distinction

Don't confuse:

```bash
git worktree remove
```

with:

```bash
git branch -d
```

They operate on **different objects**:

```text
git worktree remove
        ↓
filesystem checkout


git branch -d
        ↓
branch reference
```

So deleting a worktree does **not mean deleting the branch**. That's a very important part of the Git mental model.


[[Git & Github]]