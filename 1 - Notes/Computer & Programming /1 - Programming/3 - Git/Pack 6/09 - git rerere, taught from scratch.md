


## 1. The problem it solves

To understand rerere, you first need to know what a **merge conflict** is.

When you combine two lines of work (a _merge_, or a _rebase_, which replays your commits on top of another branch), Git usually combines changes automatically. But if both sides changed **the same lines of the same file** differently, Git can't decide which is right. It stops and asks you. That's a conflict, and Git marks the file like this:

```
<<<<<<< HEAD
timeout = 30
=======
timeout = 60
>>>>>>> feature
```

You edit the file to the correct result, `git add` it, and continue. Fine, once.

The pain: in some workflows you hit the **same conflict again and again**. For example:

- You rebase a long-running feature branch onto `main` every few days, and the same lines conflict each time.
- You try a merge, abort it, and redo it later.
- You rebuild a temporary "integration" branch from scratch repeatedly.

Resolving the identical conflict by hand over and over is tedious and error-prone.

## 2. What rerere is

**rerere = "reuse recorded resolution."**

It is a feature that:

1. **Watches** you resolve a conflict.
2. **Records** the conflict and your fix.
3. **Replays** your fix automatically when the same conflict reappears.

It is off by default.

## 3. How it works internally

When enabled, Git stores two snapshots for each conflict, in `.git/rr-cache/`:

|Name|Meaning|
|---|---|
|**preimage**|The file with conflict markers, before you fixed it|
|**postimage**|The same file after you resolved it|

Each conflict is identified by a **hash of the conflict's content** (the conflicting text on both sides, ignoring surrounding context). The hash is the folder name inside `rr-cache`.

When a new conflict appears, Git hashes it. If the hash matches a stored one that has a postimage, Git applies that resolution for you.

## 4. Setting it up

```bash
git config --global rerere.enabled true
```

`--global` applies to all your repos. Omit it for just the current one.

## 5. A concrete walkthrough

Say `config.txt` contains `timeout = 10` on both branches' common ancestor. On `main` it becomes `30`; on `feature` it becomes `60`.

**First time:**

```bash
git checkout feature
git merge main
# CONFLICT in config.txt
# Recorded preimage for 'config.txt'     <-- rerere saved the conflict
```

You fix the file to `timeout = 45`, then:

```bash
git add config.txt
git commit
# Recorded resolution for 'config.txt'.  <-- rerere saved your fix
```

**Later, same conflict arises** (say you reset and redo the merge):

```bash
git reset --hard HEAD~1     # undo the merge
git merge main
# Resolved 'config.txt' using previous resolution.
```

The file now already contains `timeout = 45`. One important detail: Git **does not stage it automatically**. It leaves that to you so you can review first. You then run `git add config.txt` and commit.

## 6. Commands you'll use

```bash
git rerere status          # which files rerere is tracking right now
git rerere diff            # what's changed vs. the recorded conflict
git rerere forget <path>   # delete a recorded resolution that was wrong
git rerere gc              # clean up old records
```

## 7. Pitfalls

- **A wrong resolution gets reused.** If you recorded a bad fix, rerere will keep applying it. Use `git rerere forget <path>` to remove it.
- **It's local.** `rr-cache` lives in your `.git` folder and isn't pushed, so teammates don't get your recorded resolutions.
- **Always review.** Same conflict text doesn't guarantee the same correct answer in a different context.

## Summary

Conflict happens, you fix it once, Git remembers, and the next identical conflict is fixed for you. It's a memory for your conflict resolutions.




[[Git & Github]]