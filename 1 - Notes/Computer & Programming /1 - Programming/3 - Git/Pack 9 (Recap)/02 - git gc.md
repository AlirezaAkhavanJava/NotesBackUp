`git gc` stands for "garbage collection". It is Git's tidy-up command. As you work, Git leaves a lot of small files and old leftovers behind: loose objects, abandoned commits, expired reflog entries. `git gc` packs them into compact files and throws away what nobody needs anymore.

Most of the time you never run it yourself. Git quietly runs it for you when things get messy. Knowing what it does helps you in two ways: you understand why your repo sometimes pauses for a moment, and you know when a manual run is worth it, and when it is risky.

## What it does

Think of it as tidying a desk in four moves:

|Move|What happens|Why it helps|
|---|---|---|
|**Pack**|Loose object files are bundled into packfiles|Less disk space, faster reads|
|**Prune**|Unreachable objects older than 2 weeks are deleted|Frees space. Only truly orphaned data goes|
|**Expire**|Old reflog entries are dropped (90 days, or 30 for unreachable ones)|Keeps the reflog from growing forever|
|**Refresh**|References are compacted and the commit graph is updated|Faster branch and history lookups|

"Unreachable" means no branch, tag, or reflog entry points to the object anymore, so nothing can get to it.

## When it runs by itself

After commands like `commit`, `merge`, `fetch`, `pull`, and `rebase`, Git runs `git gc --auto`. That checks two limits and only cleans up if one is exceeded:

|Setting|Default|Meaning|
|---|---|---|
|`gc.auto`|6700|Loose objects before a cleanup starts|
|`gc.autoPackLimit`|50|Packfiles before they get merged|

By default, it runs in the background (`gc.autoDetach true`), so your terminal isn't blocked for long. If you used `git maintenance start`, that already set `maintenance.auto=false`, so this auto-cleanup is replaced by the scheduled tasks.

## Running it by hand

```bash
git count-objects -vH      # check first: how messy is it?
git gc                     # normal cleanup
```

In the `count-objects` output, the lines to watch are `count` and `size` (loose objects), `packs`, and `size-pack`. A large loose `count` means a cleanup will help.

|Option|Use|
|---|---|
|`git gc --auto`|Only clean if the thresholds say so|
|`git gc --aggressive`|Slower, deeper repack. Rarely worth it, since the defaults are already good|
|`git gc --prune=now`|Delete unreachable objects immediately, with no 2-week grace period|
|`git gc --quiet`|Hide progress output|

## The one danger

`git gc --prune=now` can permanently delete work you might still want. The 2-week grace period exists so you can recover lost commits with the reflog. Remove it and the safety net is gone.

The really destructive combination is this:

```bash
git reflog expire --expire=now --all
git gc --prune=now      # unreachable commits are now gone for good
```

Run it only when you truly want old data erased, and never as a casual fix.

## Common questions

**It ran, but my repo is still big. Why?**  
Objects that are still reachable stay, including old branches, tags, remote-tracking branches, and reflog entries. To remove a huge file from all history, you need a history-rewriting tool like `git filter-repo`, and then a `gc`.

**It says `gc.log` exists and refuses to run.**  
An earlier automatic run failed and left `.git/gc.log`. Read the file, fix the cause, and delete it. Git also ignores it after a day by default.

**Should I run it regularly?**  
Usually no. Run it after big events, like deleting many branches, a large rebase, or a history rewrite. Otherwise let Git decide.

## Settings you may tune

```bash
git config gc.auto 6700
git config gc.pruneExpire "2.weeks.ago"
git config gc.reflogExpire "90.days"
git config gc.reflogExpireUnreachable "30.days"
```

Raise the expiry times if you want a longer safety net.

## Quick summary

- `git gc` packs, prunes, expires, and refreshes.
- Git runs it automatically at thresholds, so manual runs are rare.
- Check with `git count-objects -vH` first.
- Treat `--prune=now` as permanent.
- If you use `git maintenance`, you can think of `gc` as one task inside it.



[[Git & Github]]