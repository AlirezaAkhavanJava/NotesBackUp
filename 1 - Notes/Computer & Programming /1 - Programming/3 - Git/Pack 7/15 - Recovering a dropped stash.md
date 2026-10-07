


## Definition first

A **dropped stash** is a stash you removed from the stash list with `git stash drop` (or `git stash clear`). The key fact: **`drop` does not delete the stash commit from Git's object database.** It only removes the reference (`refs/stash`) that pointed to it. The commit object still exists on disk, unreferenced, until Git's garbage collector (`git gc`) runs and prunes it.

That gap — between "dropped" and "actually deleted by gc" — is the entire window you're recovering from.

## Why this works at all

Git's object model treats every commit, tree, and blob as content-addressed and immutable. Deleting a *reference* to an object doesn't delete the object. The object becomes **unreachable** (nothing points to it), which is what `gc` eventually cleans up. Until then, it's still in `.git/objects` and you can find it.

For a stash specifically, the thing you're recovering is a **commit** (or a chain of 2–3 commits: the working-tree state, the index state, and sometimes an untracked-files commit). So recovery is really: *find the unreachable stash commit, then re-register it in `refs/stash`.*

## Method 1 — You have the hash (the easy case)

If your terminal still shows the drop output:

```
Dropped stash@{1} (5fd40db3fa52a06d54bd3dfbbefb362d50ddadfa)
```

That hash **is** the stash commit. Bring it back:

```bash
git stash store -m "What a day" 5fd40db3fa52a06d54bd3dfbbefb362d50ddadfa
```

`git stash store` registers an existing stash-shaped commit under `refs/stash`, so it shows up in `git stash list` again. The `-m` is just a label; the hash is what matters.

This is the case from your earlier session. It's the cleanest recovery path.

## Method 2 — You don't have the hash

You scroll back, and the hash is gone. Now you go find it.

**First, check the stash reflog.** Every stash operation is journaled:

```bash
git reflog show stash
```

You'll see entries like:

```
5fd40db stash@{0}: drop: What a day
abc1234 stash@{0}: apply: What a day
...
```

The `drop:` line gives you the exact hash. Then `git stash store` it as above. This is the most common real-world recovery — the reflog is your safety net, and it's local-only, so it works even if you never wrote the hash down.

**If the reflog doesn't have it either**, scan for unreachable commits:

```bash
git fsck --unreachable | grep commit
```

That lists commit hashes nothing references. You then inspect candidates:

```bash
git log -1 --stat <hash>       # does it look like your stash?
git stash show <hash>          # if it's a stash, this summarizes it
git show <hash>                # full diff
```

Stash commits have a recognizable shape — their message is usually `WIP on <branch>: <short-hash> <subject>` or `On <branch>: <your label>`. You'll spot yours.

Once you've identified it:

```bash
git stash store -m "recovered" <hash>
```

## Method 3 — You only want the *contents*, not the stash entry

You don't actually need it back in the stash list. You just want the changes on disk. Then skip `store` and apply the raw commit directly:

```bash
git stash apply <hash>
```

`git stash apply` accepts any stash-shaped commit, referenced or not. This is often what you really want — you're not trying to preserve stash history, you're trying to get your work back.

Or, if you'd rather put it on its own branch (cleaner when the stash is tangled, like your earlier session):

```bash
git stash branch recover-branch <hash>
```

This creates a branch, checks it out, applies the stash, and drops it from the list — all in one step.

## The deadline

Recovery works until `git gc` prunes the unreachable object. By default:

- `git gc` runs automatically after certain operations (roughly when loose objects pile up or after `git merge`/`git rebase` triggers auto-gc).
- Default prune window for unreachable objects is **2 weeks** (`gc.pruneExpire`), but auto-gc can be more aggressive in some configs.
- `git gc --prune=now` deletes unreachable objects immediately, no grace period.

So the practical rule: **recover soon, and don't run `git gc --prune=now` until you have.** After a real prune, the object is genuinely gone and no method recovers it.

## The one thing people get wrong

They run `git fsck --unreachable`, see a wall of hashes, and panic because they can't tell which is the stash. The fix is to filter and inspect — `git fsck` output for a stash commit usually contains `commit <hash>` followed by nothing that identifies it, so you have to `git show`/`git log -1` each candidate. Tedious, but deterministic. There's no magic "show me my stash" command for this case; the identification is manual.

## Quick reference

| Situation | Command |
|---|---|
| You have the hash | `git stash store -m "label" <hash>` |
| You have the hash, want contents only | `git stash apply <hash>` |
| You have the hash, want a branch | `git stash branch <name> <hash>` |
| You lost the hash | `git reflog show stash` → find `drop:` line |
| Reflog also lost it | `git fsck --unreachable \| grep commit`, then `git show <hash>` to identify |
| Deadline | Until `git gc` prunes unreachable objects (~2 weeks default) |

[[Git & Github]]