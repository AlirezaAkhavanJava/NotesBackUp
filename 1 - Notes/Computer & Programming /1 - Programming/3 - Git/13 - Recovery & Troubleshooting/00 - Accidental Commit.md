

You know how with `merge` conflicts you _commit_ the resolution, but with `rebase` conflicts you `--continue` the resolution?

I cannot tell you how many times I have accidentally committed the resolution of a rebase conflict...

## How to Undo the Screw-Up

If you accidentally commit the resolution of a rebase conflict, just:

```sh
git reset --soft HEAD~1
```

The [`--soft` flag](https://git-scm.com/docs/git-reset#Documentation/git-reset.txt---soft) will keep your changes, and just undo the commit. Then you can simply `--continue` the rebase as normal.

---
**Answer: 1.** You can undo the commit and then continue the rebase.

## Why this works

During a rebase, Git replays your commits one at a time onto a new base. When a conflict stops it, Git is _mid-operation_: it has written state into `.git/rebase-merge/` (which commit it's applying, what's left to do, and so on). `git rebase --continue` reads that state, creates the commit for the step you resolved, and moves on.

If you run `git commit` yourself, you create the commit _before_ Git does. The rebase machinery still thinks the current step is unfinished, so `--continue` has nothing left to commit and gets confused (or produces an extra, unintended commit).

`git reset --soft HEAD~1` fixes this because:

- It moves the branch pointer back one commit (undoing your manual commit).
- It leaves your **index and working tree untouched**, so your conflict resolution is still staged.
- The rebase state in `.git/rebase-merge/` is unaffected, so Git is back in the "step needs finishing" position.

Then `git rebase --continue` makes the commit properly, with the original commit's message and authorship.

## Why the other options are wrong

- **2:** `reset` doesn't exit the rebase or create a branch. That would be `git rebase --abort`.
- **3:** `--soft` deletes nothing. Even `--hard`, which does discard working changes, wouldn't be what you want here.

## Gotchas

- **Use `--soft`, not `--hard` or `--mixed`.** `--mixed` (the default) unstages your resolution, so you'd have to `git add` again. `--hard` throws the resolution away.
- **Safety net:** if you're unsure, `git reflog` shows where HEAD was before the reset, so you can get back to your accidental commit with `git reset --soft HEAD@{1}`.
- **Check state first:** `git status` will say "interactive rebase in progress" (or "rebase in progress") so you know you're in the situation described.
- **Sometimes you don't even need to undo it.** If the accidental commit is harmless, you can finish the rebase and clean up afterward with `git rebase -i`, but resetting first is cleaner.

This ties back to the earlier branch-deletion topic: both are cases where Git's safety depends on understanding that commits are just objects pointed to by refs, and that moving a ref (here with `reset`, there with `branch -D`) doesn't destroy the work.


[[Git & Github]]