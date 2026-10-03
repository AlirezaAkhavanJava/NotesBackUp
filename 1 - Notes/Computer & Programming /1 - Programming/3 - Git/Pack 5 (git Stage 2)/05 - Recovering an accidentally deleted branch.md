

## 1. Core intuition

A branch is just a **sticky note** with a commit hash written on it. Deleting a branch peels off the sticky note. It does **not** destroy the commits it pointed to. Those commits stay in Git's warehouse (the object database) until the janitor (`git gc`) eventually discards unprotected ones.

So recovery is always the same job: **find the hash that was on the sticky note, then write a new sticky note with that hash.**

```bash
git branch <name> <hash>
```

Everything below is about finding that hash, as fast as possible.

## 2. Step zero: read what Git just told you

When you delete a branch, Git often prints the answer immediately:

```
$ git branch -D feature/auth
Deleted branch feature/auth (was 8d4e0b7).
```

That `8d4e0b7` is the tip of the deleted branch. If you can still see it in your terminal scrollback, you're done:

```bash
git branch feature/auth 8d4e0b7
```

If you only deleted it a moment ago, scroll up before running anything else.

## 3. The reliable method: the reflog

If the output is gone, use the `HEAD` reflog. It records every commit you made and every checkout, including on branches that no longer exist.

```bash
git reflog
```

You're looking for one of these clues:

- **The last `commit:` line made on that branch**, right before a `checkout: moving from feature/auth to main` line. That `checkout` line is the strongest marker, because it names the branch you were leaving.
- Entries mentioning the branch name, so filter for them:

```bash
git reflog | grep feature/auth
```

Example:

```
c91d5a0 HEAD@{0}: checkout: moving from feature/auth to main
8d4e0b7 HEAD@{1}: commit: Fix null check in TaskService
2b7c1fe HEAD@{2}: commit: Add TaskController
```

Here the last commit on the branch was `8d4e0b7` (line `{1}`, the one just _below_ the checkout, since the older line is below). Check before restoring:

```bash
git show 8d4e0b7          # is this the work I expect?
git log --oneline 8d4e0b7 # does the chain of commits look right?
```

Then restore:

```bash
git branch feature/auth 8d4e0b7
```

Using `git branch <name> <hash>` creates the label without switching to it. If you want to switch immediately, `git switch -c feature/auth 8d4e0b7` does both.

**Why this works:** the commits were never edited or removed. Only the label vanished, and the reflog kept a record of where `HEAD` stood, so the hash is still on file.

**Mistake to avoid:** don't use the first `commit:` line you see. Branches can hold many commits, and you want the **newest** one (the tip), not an early one. Restoring the tip brings the whole chain along, because each commit points to its parents.

## 4. Check the remote first, it may be the quicker route

If you ever pushed the branch, a copy likely still exists:

```bash
git branch -r                    # list remote-tracking branches
git log origin/feature/auth      # inspect it
git branch feature/auth origin/feature/auth   # recreate locally
```

Or simply:

```bash
git switch feature/auth
```

Git auto-creates a local branch tracking `origin/feature/auth` if exactly one remote has it.

**Nuance:** `origin/feature/auth` is your _local cache_ of the remote's state, updated on `git fetch`. If you fetched with `--prune` after the branch was deleted on the server, that cache entry is gone too. Then the reflog route (or the server itself) is needed.

## 5. If you deleted the branch on the remote too

Deleting a local branch and deleting a remote branch are separate actions (`git push origin --delete feature/auth`). If the remote one is gone:

- **GitHub:** a closed pull request keeps its commits, and deleted-branch PRs show a **Restore branch** button on the PR page. You can also fetch the PR head directly: `git fetch origin refs/pull/<number>/head:feature/auth`.
- **GitLab:** the project's _Branches_ page and the commit history in merge requests can help; merged or MR-associated commits are often still reachable.
- **Any server:** if you know the commit hash, `git push origin <hash>:refs/heads/feature/auth` from a machine that still has the commits recreates the branch.
- **Teammates' clones** often still have the branch.

## 6. Merged vs unmerged: why `-d` and `-D` differ

|Command|Behavior|
|---|---|
|`git branch -d name`|Safe delete: refuses if the branch has commits not merged into the current branch or its upstream|
|`git branch -D name`|Force delete (shorthand for `--delete --force`): deletes regardless|

If you used `-d` and it succeeded, the commits were already merged somewhere, so the work is safe in the history of the branch you merged into. Nothing was actually lost, just the label. If you used `-D`, the commits may exist **only** on that deleted branch, so recover them soon.

## 7. If the reflog doesn't show it

This is uncommon, but it happens in these cases:

- **The branch was created in another clone or worktree.** Reflogs are per repository, and each linked worktree has its own `HEAD` reflog.
- **The entries expired** (90 days reachable, 30 days unreachable by default).
- **The branch's commits were made on the remote or in a different clone** and you never had them locally.

Then search the object database directly:

```bash
git fsck --lost-found
```

List dangling commits with dates and subjects, spot yours, and recover with `git branch rescued <hash>`. Use `git config gc.auto 0` first so nothing is pruned while you search. The full procedure is in my previous answer on reviving long-forgotten content.

## 8. Edge cases and gotchas

- **Deleting the branch you're on isn't allowed.** Git refuses, so you were on another branch or detached when it happened.
- **The branch's own reflog is deleted with it**, because it's stored at `.git/logs/refs/heads/<name>`. That's why you use the `HEAD` reflog, which survives.
- **Recreating restores the label but not uncommitted work.** Changes you never committed (or staged) were not on the branch.
- **Stale hash reuse:** if you recreate the branch with a name that already exists, Git refuses. Pick a new name, or delete the existing one first.
- **Upstream tracking is lost.** After restoring, reconnect it: `git branch --set-upstream-to=origin/feature/auth feature/auth`.
- **Don't rush `git gc`.** Avoid `git gc --prune=now` and `git reflog expire --expire=now --all` until you've recovered everything.

## 9. Quick checklist

1. Check terminal scrollback for `Deleted branch X (was <hash>)`.
2. `git reflog | grep <branch>`, find the last commit before the `checkout: moving from <branch>` line.
3. `git show <hash>` to verify, then `git branch <branch> <hash>`.
4. If not found, check `git branch -r` and the remote's web UI (PR restore, `refs/pull/N/head`).
5. If still not found, `git fsck --lost-found`, then ask teammates or check other clones.

## 10. Prevention

- Prefer `git branch -d` over `-D`; the refusal is a free safety check.
- Push branches you care about to the remote regularly.
- Before deleting, a quick `git log main..feature/auth` shows commits that exist only on the branch.




[[Git & Github]]