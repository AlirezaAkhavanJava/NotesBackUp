
### “No Duplicate Branches” Rule in Git Worktrees

This is the #1 most important (and most misunderstood) rule when using `git worktree`:

> **One branch can be checked out in at most ONE worktree at a time.**

Git will actively prevent you from creating a second worktree on a branch that is already checked out somewhere else.

#### What happens if you try to break the rule

```bash
# You already have main checked out in the main worktree
git worktree add ../myproject-main2 main
# → fatal: 'main' is already checked out at '/path/to/myproject-main'
```

Same thing the other way around:

```bash
# You created a worktree on feature/x first
git worktree add ../myproject-feature feature/x
# Then from the main repo you try to switch to it
git switch feature/x
# → fatal: 'feature/x' is already checked out at '/path/to/myproject-feature'
```

Git refuses both directions.

#### Why this rule exists

- Git stores the current branch and HEAD in `.git/worktrees/<name>/HEAD`.
- Allowing the same branch in two places would make ref updates ambiguous and race-prone.
- It forces you to think in terms of “one working copy per branch” — which is exactly what worktrees are designed for.

#### Correct ways to work around it (when you really need “duplicates”)

| Goal                                          | Recommended solution                                                                                 |
|-----------------------------------------------|------------------------------------------------------------------------------------------------------|
| Experiment on the same branch without affecting your current work | `git worktree add -b temp-experiment ../proj-exp` (create a new temporary branch)                   |
| Compare two states of the same branch (e.g. before/after a change) | Just use two different commits: <br>`git worktree add ../proj-old <commit-ish>` <br>`git worktree add ../proj-new HEAD` |
| Temporarily duplicate a branch for a quick test | `git worktree add -b branch-copy ../proj-copy branch-name` then delete it when done                |
| You really need two independent working dirs on the exact same branch | You can’t with worktrees → fall back to `git clone` or `git clone --work-tree` hacks (not recommended) |

#### Quick one-liner to see which worktree has your branch

```bash
git worktree list | grep $(git rev-parse --abbrev-ref HEAD)
# or for any branch
git worktree list | grep branch-name
```

#### Bonus: Forcing it anyway (don’t do this in shared repos)

There is a hidden escape hatch (use at your own risk):

```bash
git worktree add --force ../duplicate-branch branch-name   # allows it once
# Git will warn you and you can even do it twice with --force twice, but things break quickly.
```

Never use `--force` on shared or important repositories — you will corrupt refs.

#### Summary

Correct mental model:
Worktrees = “checkout many branches in parallel”  
Not = “checkout the same branch many times”





###### Tags : [[0 - Git 🍋‍🟩]]