“Types of Git merge” can mean two related things: **how history is recorded** and **which merge strategy handles the content**. Here’s the practical breakdown.

## 1. By resulting history

| Type | Command | What it does | Merge commit? |
|---|---|---|---|
| **Fast-forward merge** | `git merge feature` | If current branch is an ancestor of `feature`, Git just moves the branch pointer forward. No new commit. | No |
| **Three-way / true merge** | `git merge feature` | Branches have diverged. Git finds the common ancestor and combines both histories. | Yes, with two parents |
| **Squash merge** | `git merge --squash feature` | Takes all changes from `feature` and stages them as one set of changes. You then make a normal commit. | No |
| **Octopus merge** | `git merge branch1 branch2 branch3` | Merges more than two branches at once. Creates a merge commit with multiple parents. Aborts on conflicts. | Yes, with 3+ parents |
| **Ours merge** | `git merge -s ours feature` | Records that `feature` was merged, but keeps the current branch’s tree exactly. Useful to mark something as merged while ignoring its changes. | Yes |
| **Subtree merge** | `git merge -s subtree repo` | Merges another project into a subdirectory. Used for vendor/subproject workflows. | Yes |

### Fast-forward details
- Default when possible.
- `git merge --no-ff feature` forces a merge commit even if fast-forward is possible.
- `git merge --ff-only feature` fails if fast-forward is not possible.

### Three-way details
- This is the normal “real merge.”
- Git uses the **merge base** — the best common ancestor — to combine changes.
- Conflicts are possible and must be resolved manually.

### Squash details
- Good for keeping a feature branch as one clean commit on `main`.
- Does **not** preserve the branch ancestry, so Git does not know the branch was merged.

### Octopus details
- Mainly for merging several independent branches at once.
- It cannot resolve conflicts; if there is a conflict, the whole merge aborts.

### Ours vs `-X ours`
- `git merge -s ours branch` → completely ignores the other branch’s tree.
- `git merge -X ours branch` → still merges the other branch, but when conflicts occur, favors your current branch’s version.
- There is no true `-s theirs` strategy in Git; `-X theirs` only affects conflict resolution.

## 2. By merge strategy

Git’s content-combining strategies include:

| Strategy | Use |
|---|---|
| **ort** | Default modern strategy. Handles most two-branch merges, renames, etc. |
| **recursive** | Older default for two-branch merges. Replaced by `ort` in newer Git versions. |
| **resolve** | Simple two-head merge strategy. Less common now. |
| **octopus** | For merging multiple branches/heads at once. |
| **ours** | Ignores the other branch’s changes but records the merge. |
| **subtree** | Merges into a subdirectory. |

## Quick summary

Most everyday merges are one of these:

- **Fast-forward** — just moves the branch pointer.
- **Three-way merge** — creates a merge commit because histories diverged.
- **Squash merge** — combines changes into one normal commit, no merge history.
- **Octopus merge** — merges several branches at once.
- **Ours merge** — records a merge but keeps your current content.
- **Subtree merge** — merges another project into a subdirectory.

The key distinction: **fast-forward / three-way / squash** describe the resulting history, while **ort / recursive / octopus / ours / subtree** describe the strategy Git uses to combine content.

[[0 - Git 🍋‍🟩]]