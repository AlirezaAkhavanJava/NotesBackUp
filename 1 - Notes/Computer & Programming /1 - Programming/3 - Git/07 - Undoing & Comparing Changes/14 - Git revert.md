

## Definition first

`git revert` creates a **new commit** that undoes the changes introduced by an earlier commit. It doesn't erase history — it adds to it. The target commit stays exactly where it is; the revert commit sits on top, applying the inverse of that commit's diff.

That's the whole idea, and it's the opposite of what most people assume. It sounds like "go back," but it actually means "move forward by undoing."


>A revert is effectively an _anti_ commit. It does not _remove_ the commit (like `reset`), but instead creates a new commit that does the exact opposite of the commit being reverted. It undoes the change but keeps a full history of the change and its undoing.

## Using Revert

To revert a commit, you need to know the commit hash of the commit you want to revert. You can find this hash using `git log`.

```sh
git log
```

Once you have the hash, you can revert the commit using `git revert`.

```sh
git revert <commit-hash>
```

## Assignment

In your great haste and pursuit for greatness at MegaCorp™ you forgot to write a white paper and get approval from the L69 distinguished staff architect for your marketing documentation change. The L69 has requested you revert the change...

1. [ ] Ensure you're on `main`
2. [ ] Revert the `M` commit
3. [ ] It should prompt you to write a commit message. Edit the message to be:

```
N: Revert M

This reverts commit <commit-hash>
```

**Run and submit** the CLI tests.

Boots

Spellbook

Lessons

![Boots](https://www.boot.dev/_nuxt/new_boots_profile.DriFHGho.webp)

**Need help?** I, Boots the Bear with a Back-End, can assist... _for a price_.

Copy/paste one of the following commands into your terminal:

Run

bootdev run 4739f014-45dc-4de6-ab9d-4f04e326e606

Submit

bootdev run -s 4739f014-45dc-4de6-ab9d-4f04e326e606

To run and submit the tests for this lesson, you must have an active Boot.dev membership

Become a Member

Solution Files

Using the Bootdev CLI

The Bootdev CLI is the only way to submit your solution for this type of lesson. We need to be able to run commands in your environment to verify your solution.

You can [install it here](https://github.com/bootdotdev/bootdev). It's a Go program hosted on GitHub, so you'll need Go installed as well. Instructions are on the GitHub page.

## Why this exists — and why it's not `reset`

You've probably heard of `git reset`. They both "undo" things, so people confuse them. The distinction is the entire reason `revert` exists:

- **`git reset`** moves your branch pointer backward. The commits you "undid" disappear from the branch's history. If you've pushed, this rewrites published history — which breaks everyone else's clone.
- **`git revert`** leaves history intact and appends a new commit that cancels out an old one. Nothing is rewritten. It's safe on shared branches.

So the problem `revert` solves: *"A commit is already pushed, other people have it, and I need to undo its effect without rewriting history."* That's it. That's the use case. On a local-only branch you haven't pushed, `reset` is often simpler — but the moment the commit is public, `revert` is the correct tool.

## How it actually works

When you run:

```bash
git revert <commit>
```

Git does this:

1. Looks at the diff `<commit>` introduced — i.e., `<commit>` versus its parent.
2. Computes the **inverse** of that diff — lines added become removed, lines removed become added.
3. Applies that inverse to your current working tree.
4. Opens an editor for a new commit message, pre-filled with something like `Revert "<original subject>"`.
5. Commits it.

The result is a normal commit. It has a parent, a message, a diff. From Git's perspective nothing special happened. From your project's perspective, the original change is gone — but the record that it *happened* is preserved, and so is the record that you undid it.

## A concrete example, walked through

Say your history looks like this:

```
d311e4b  (HEAD) Fix login redirect
9a1c2f0  Add user profile page
5e7b8a1  Update README
```

You discover `9a1c2f0` broke something. You run:

```bash
git revert 9a1c2f0
```

Git computes the inverse of what `9a1c2f0` changed, applies it, and makes a new commit:

```
f4a2b91  (HEAD) Revert "Add user profile page"
d311e4b  Fix login redirect
9a1c2f0  Add user profile page
5e7b8a1  Update README
```

Notice:
- `9a1c2f0` is **still there**. Not deleted, not moved.
- `d311e4b` is still there too — revert didn't touch it.
- The new commit `f4a2b91` reverses only what `9a1c2f0` did. The login fix and README stay.

If you later want the profile page back, you can revert the revert:

```bash
git revert f4a2b91
```

That re-applies `9a1c2f0`'s changes as yet another new commit. This "revert the revert" pattern is how you undo an undo without rewriting anything.

## Conflict behavior

If later commits have touched the same lines the target commit touched, the inverse diff won't apply cleanly and you'll get a conflict:

```
Auto-merging app.js
CONFLICT (content): Merge conflict in app.js
error: could not revert 9a1c2f0... Add user profile page
```

At that point:
- Your working tree has conflict markers.
- The revert is **not committed** — it's paused.
- Resolve the conflicts, `git add` the files, then `git revert --continue`.
- Or abandon it with `git revert --abort`.

This is normal merge-conflict handling. Same muscle as resolving a merge or rebase conflict.

## Reverting multiple commits

A few forms worth knowing:

```bash
git revert <hash>              # revert one commit
git revert <hash1> <hash2>     # revert two, as two separate revert commits
git revert HEAD~3..HEAD        # revert a range
git revert -n <hash>           # revert but don't commit yet, so you can batch
```

The `-n` (`--no-commit`) flag is the useful one when reverting several commits: it applies all the inverses to the working tree and staging area without committing, so you can review the combined result and make a single revert commit. Without it, reverting a range makes one revert commit per target commit, which is often noisier than you want.

**Order matters in a range.** `git revert A..B` reverts in reverse chronological order — newest first — because that's usually what applies cleanly. If you revert oldest-first, later commits' context is missing and you'll get more conflicts.

## Where you actually use this

- **Undoing a pushed commit.** The canonical case. Someone merged a bad change; you can't `reset` because it's public; you `revert`.
- **Undoing a merge commit.** Needs `-m`: `git revert -m 1 <merge-hash>`. The `-m 1` says "keep parent 1, undo parent 2's contribution." This is its own rabbit hole — reverting merges has a famous trap where re-merging later doesn't restore the reverted changes, because Git thinks they were already merged. Worth a separate lesson if you hit it.
- **Backing out a change while keeping the audit trail.** Compliance, code review, blame archaeology — all benefit from the "we did it, then we undid it, both visible" record.
- **Reverting a revert.** When a change was pulled for a good reason but the reason no longer applies.

## The trap to internalize

`revert` doesn't "remove" a commit from history. If you `git log`, you'll see both the original and the revert. Some people expect the commit to vanish and are confused when it's still there. It's not supposed to vanish. If you need it gone from history, that's `reset` or `rebase` — and only on branches you haven't shared.

## Quick comparison

| | `git revert` | `git reset` |
|---|---|---|
| Moves history? | No, appends | Yes, rewrites |
| Safe on pushed branches? | Yes | No |
| Removes the original commit? | No | Yes (from the branch) |
| Conflict-prone? | Sometimes | Rarely, but destructive |
| Audit trail? | Preserved | Erased |






[[Git & Github]]