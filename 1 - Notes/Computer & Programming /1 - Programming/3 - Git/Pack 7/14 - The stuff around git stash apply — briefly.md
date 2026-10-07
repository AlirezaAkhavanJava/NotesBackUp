

## `git stash pop`

**Definition:** Applies the stash to your working tree, then deletes it from the stash list if the apply succeeds.

The key word is *if*. If the apply hits a conflict, `pop` does **not** drop the stash — it leaves it there so you don't lose it. So `pop` is only "destructive" on the happy path. On the conflict path it behaves like `apply`.

The trade-off: `pop` is convenient when you're confident the re-apply will be clean. `apply` is safer when you're not, because you keep the stash as a fallback even after a successful apply.

## `git stash push` vs `git stash save`

**Definition:** `push` is the current command for creating a stash. `save` is the deprecated older form.

`push` supports:
- `-m "message"` — label the stash so `git stash list` is readable.
- `-u` / `--include-untracked` — also stash files Git isn't tracking yet.
- `-a` / `--all` — also stash ignored files.
- A pathspec — stash only specific files: `git stash push -- app.js styles.css`.

`save` supports a message but not pathspecs and is being phased out. If you see `save` in old docs or scripts, that's why.

## Stashing untracked files (`-u`)

**Definition:** By default, `git stash` only stashes changes to files Git already tracks. Untracked files (new files you haven't `git add`ed) are left in your working tree. `-u` includes them in the stash.

Why it matters for `apply`: if you stashed with `-u`, the apply restores those untracked files too. If you didn't, they were never in the stash and `apply` can't bring them back. This trips people up constantly — they stash, switch branches, come back, and their new files "vanished" from the stash's perspective because they were never in it.

## The management commands

- `git stash list` — show the stack. `stash@{0}` is the most recent.
- `git stash show stash@{n}` — summarize what's in a stash (`-p` for the full diff).
- `git stash drop stash@{n}` — delete one stash.
- `git stash clear` — delete all stashes. No confirmation. Be careful.

## Stash internals

**Definition:** A stash is not a branch. It's a commit object (or a small chain of them) stored under `refs/stash`, with the index and working-tree states captured as separate parents.

That's *why* `--index` exists: the stash genuinely stores your index state separately, and `apply` without `--index` just doesn't restore that part. It's not a quirk; it's a direct consequence of how the stash is built.

## `git worktree`

**Definition:** A command that lets you check out multiple branches into separate directories at the same time, all sharing one repo.

Instead of stashing to switch context, you create a second working directory for the other branch and just `cd` there. No stashing, no re-applying, no conflicts from stale changes. Many seniors prefer this for anything beyond a quick context switch, because it sidesteps the entire stash workflow.

---

## Quick comparison table

| Command / concept | What it does | Destructive? | When you reach for it |
|---|---|---|---|
| `git stash apply` | Re-applies stash, keeps it in the list | No | You're unsure the apply will be clean, or you want to retry |
| `git stash apply --index` | Re-applies stash **and** restores staged state | No | You had staged changes before stashing and want them staged again |
| `git stash pop` | Applies stash, drops it on success | Yes (on success only) | You're confident, and you don't need the stash anymore |
| `git stash push -m "msg"` | Creates a labeled stash | No | Normal stash creation |
| `git stash push -u` | Stashes tracked **and** untracked files | No | You have new files you don't want to lose or commit |
| `git stash save` | Old form of `push` | No | Legacy only — prefer `push` |
| `git stash list` | Shows the stash stack | No | You need to see what's stashed |
| `git stash show -p` | Shows a stash's full diff | No | You want to inspect before applying |
| `git stash drop stash@{n}` | Deletes one stash | Yes | You're done with it |
| `git stash clear` | Deletes all stashes | Yes, no confirm | Rarely — usually a mistake |
| Stash internals | Commit object(s) under `refs/stash` | — | Explains why `--index` exists |
| `git worktree` | Multiple working dirs, one repo | No | You'd rather not stash at all |

---

One flag on the table itself: "destructive" here means *destroys the stash*, not *destroys your work*. Even a dropped stash is recoverable for a while via `git fsck --unreachable` + `git stash apply <commit>`, because Git keeps unreferenced objects around until garbage collection. That's a topic of its own if you want it.




[[Git & Github]]