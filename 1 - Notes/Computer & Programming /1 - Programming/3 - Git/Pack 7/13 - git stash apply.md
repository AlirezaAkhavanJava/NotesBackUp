
# `git stash apply`

## Definition first

`git stash apply` is the command that takes a stash entry — a saved snapshot of your working directory and staging area changes — and **re-applies those changes back onto your current working tree**, without deleting the stash from the stash list.

That last part is the whole point. `git stash apply` restores changes but *keeps the stash around*. Its sibling `git stash pop` restores changes *and* deletes the stash. That distinction is where most of the real-world nuance lives, so keep it in your head from the start.

## Why this command needs to exist

To understand `git stash apply`, you need to understand what a stash actually is — because the command only makes sense in that context.

Your working directory has three "places" that matter here:

1. **Working tree** — the actual files on disk you're editing.
2. **Index (staging area)** — changes you've `git add`ed, queued for the next commit.
3. **HEAD / commit history** — the last committed state.

A stash is Git's way of saying: *"I have uncommitted changes I don't want to commit right now, but I don't want to lose them either. Save them somewhere and give me a clean working tree."* Internally, a stash is stored as a commit-like object (actually two or three commits: one for the index, one for the working tree, optionally one for untracked files) referenced under `refs/stash`. It's not a real branch. It's a dangling-ish reference that lives in a stack.

The problem it solves: you're mid-edit on a feature, and you need to switch branches to fix something urgent. You can't commit half-broken work, and you can't switch with a dirty tree (or you can, but it gets messy). So you stash, switch, do the thing, come back, and re-apply the stash.

Now — why `apply` specifically instead of `pop`? Because `apply` is **non-destructive to the stash**. If something goes wrong during the re-apply (merge conflict, wrong branch, wrong timing), the stash is still there. You can try again. `pop` removes it as soon as it applies, which is convenient but unforgiving.

## How it actually works

When you run:

```
git stash apply
```

Git does this:

1. Looks at the stash at the top of the stack (`stash@{0}`).
2. Takes the diff between the stash's base commit and its stored working-tree/index state.
3. Tries to **merge** that diff into your current working tree and index.
4. If it succeeds cleanly, your files now contain the stashed changes again, and the stash remains in the list.
5. If it conflicts, Git leaves conflict markers in the files, leaves the stash in place, and tells you which files conflicted. You resolve them like any other merge conflict.

You can also target a specific stash:

```
git stash apply stash@{2}
```

And you can control what gets staged:

- `git stash apply` — restores changes, but does **not** re-stage what was staged when you stashed. Everything comes back as unstaged working-tree changes (with one caveat below).
- `git stash apply --index` — also restores the **index state**, meaning files that were staged when you stashed come back staged.

That `--index` flag is a real gotcha. Without it, a file you had carefully `git add`ed before stashing will come back as unstaged, and you might not notice until you commit and realize half your changes weren't in the commit. Worth knowing.

## A concrete example, walked through

Say you're on `main` and you've edited two files:

```
# working tree state
modified:   app.js        (staged)
modified:   styles.css    (unstaged)
```

You stash:

```
git stash push -m "wip: button refactor"
```

Now your tree is clean. You do some other work on another branch. Later you come back to `main` and run:

```
git stash apply
```

What happens:

- `app.js` and `styles.css` both come back with their changes.
- **But** `app.js` comes back **unstaged**, even though you'd staged it before. That's because you didn't use `--index`.
- The stash is still in `git stash list`.

If instead you'd run `git stash apply --index`, `app.js` would come back staged, matching the state you stashed.

If you then run `git stash apply` *again* without clearing anything, Git will try to apply the same diff on top of a tree that already contains those changes — and you'll typically get "already applied" style conflicts or a message that the changes are already present. This is one of the reasons people accidentally get into a mess: they `apply` twice, or `apply` and then `pop` the same stash.

## Where you actually use this

- **Re-applying a stash onto a different branch than you made it on.** You stash on `feature-a`, realize the changes belong on `feature-b`, switch, and `apply`. `pop` works here too, but `apply` is safer because you can undo and retry.
- **Trying a stash without committing to it.** You want to see if those changes still apply cleanly after other work landed. `apply` lets you test, and if it's a disaster, `git checkout -- .` (or `git restore .`) and the stash is untouched.
- **Recovering from a botched `pop`.** If you `pop` and something goes wrong, the stash is gone from the list but not from Git's object database — you can recover it via `git fsck --unreachable` and re-`apply` the dangling commit. But this is exactly the pain that `apply` avoids in the first place.
- **Applying the same stash in multiple places.** Rare, but legitimate: you want the same set of changes on two branches. `pop` can only do it once.

## The conflict case, because it's the one that bites people

If your current branch has diverged from where you stashed, `apply` will merge and may conflict:

```
Auto-merging app.js
CONFLICT (content): Merge conflict in app.js
```

At this point:

- The stash is **still in the list**. Good — you haven't lost anything.
- Your working tree has conflict markers. Resolve them like a normal merge conflict.
- If you decide the whole thing was a mistake, `git checkout -- .` / `git restore .` to throw away the half-applied state, and the stash is still there to try later.

This is the single biggest reason to prefer `apply` over `pop` when you're not 100% sure the re-apply will be clean.




[[Git & Github]]