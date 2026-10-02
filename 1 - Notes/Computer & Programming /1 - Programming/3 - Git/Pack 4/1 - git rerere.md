
## `git rerere` — Deep Dive

(**re**use **re**corded **re**solution — the name is literally an acronym for what it does)

---

## Core Intuition First

Imagine you're doing a rebase with 10 commits, and the **same line** in the **same file** conflicts on 6 of those 10 commits — because, say, you reformatted a function signature early on, and 6 later commits all touch nearby lines. You'd resolve that identical conflict **six separate times**, by hand, doing the exact same edit each time.

`rerere` solves this: **Git remembers how you resolved a conflict the first time, and automatically applies the same resolution if that exact conflict ever happens again** — whether later in the same rebase, or in a completely different rebase/merge weeks later.

> **Mental model:** It's muscle memory for Git. The first time you resolve a conflict, Git watches and takes notes. Next time it sees the identical conflict pattern, it just applies your past fix automatically, without asking.

---

## Why This Exists — The Specific Problem It Solves

This connects directly to something from the rebase-conflicts topic earlier — recall that rebase conflicts happen **per-commit**, which can mean resolving the same underlying conflict repeatedly:

```
Rebasing 5 commits, all touching nearby lines in App.java
→ Conflict in commit 1/5 → resolve manually
→ Conflict in commit 2/5 → SAME conflict pattern → resolve manually AGAIN
→ Conflict in commit 3/5 → SAME conflict pattern → resolve manually AGAIN
...
```

This also happens in a different scenario worth naming explicitly: **long-lived feature branches that get rebased repeatedly** against a fast-moving `main`. Every time you rebase, you re-resolve the _same_ conflicts between your branch's changes and `main`'s changes, over and over, across multiple rebase sessions spread across days/weeks.

`rerere` turns "resolve this conflict" from a recurring chore into a one-time task.

---

## Enabling It

Off by default — needs to be turned on:

```bash
git config --global rerere.enabled true
```

Once enabled, it works silently in the background from that point forward — no new commands required for normal use.

---

## How It Actually Works, Mechanically

1. You hit a merge/rebase conflict, same as always — conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) appear in the file
2. You resolve it manually — exactly as covered in the conflicts topic
3. When you `git add` the resolved file, `rerere` **records** the pattern: _"this exact conflicting pre-image → resolved to this exact post-image"_ — stored in `.git/rr-cache/`
4. The **next time** Git encounters a conflict with the **identical** conflicting content, `rerere` automatically applies your previously-recorded resolution — no markers even appear, it's just... already resolved

```bash
git rerere status       # show which files currently have a recorded resolution being applied
git rerere diff          # show what rerere is about to apply, before you commit
```

---

## What "Identical Conflict" Actually Means

This is the important precision point: `rerere` matches based on **the exact content of the conflicting hunk** — not the commit, not the branch, not the overall diff. If the _same lines_ conflict with the _same opposing content_ again (even in a totally different branch, weeks later), rerere recognizes it.

If even one character differs in the conflicting region compared to what was recorded, it's treated as a **new**, unrecognized conflict — you resolve it manually again, and _that_ resolution gets recorded as a new pattern.

---

## A Concrete Walkthrough

```bash
git config --global rerere.enabled true

git rebase main
# CONFLICT in commit 1 of 5 — App.java
```

You open the file, resolve the `<<<<<<<` / `=======` / `>>>>>>>` block manually:

```bash
git add App.java
git rebase --continue
```

```bash
# CONFLICT in commit 3 of 5 — App.java, SAME underlying conflict pattern
```

This time:

```
Resolved 'App.java' using previous resolution.
```

Git already applied your fix. You just check it looks right, then:

```bash
git add App.java
git rebase --continue
```

No manual editing needed the second time — `rerere` did it for you.

---

## Clearing / Managing Recorded Resolutions

|Command|What it does|
|---|---|
|`git rerere`|Manually trigger a check/apply (usually automatic, rarely needed explicitly)|
|`git rerere status`|List files with an active recorded resolution being used|
|`git rerere diff`|Preview what rerere auto-applied|
|`git rerere forget <file>`|Discard the recorded resolution for one file (if it was wrong, or you want to re-resolve manually)|
|`rm -rf .git/rr-cache/`|Nuclear option — wipe **all** recorded resolutions for this repo|

---

## Important Nuance: It Still Requires Review

`rerere` auto-applies the resolution to the **working directory file**, but it still **stops the rebase/merge** at that commit — it doesn't silently blast through the entire operation unattended. You still see that a conflict occurred and was auto-resolved, giving you a chance to verify before continuing. It's an assistant, not something that removes your oversight entirely.

```
Auto-merging App.java
CONFLICT (content): Merge conflict in App.java
Resolved 'App.java' using previous resolution.
```

You'll still want to glance at the file (`git rerere diff` or just open it) before `git add` + `continue`, especially the first few times you're relying on it, to build trust that it's applying the right fix.

---

## Where It's Genuinely Valuable vs. Overkill

|Scenario|Worth enabling?|
|---|---|
|Solo project, rare conflicts (like `webflyx` currently)|Low value — conflicts are infrequent enough that recording/reusing resolutions rarely triggers|
|Long-lived feature branch, repeatedly rebased against active `main`|**High value** — exactly the repetitive-conflict scenario it's built for|
|Team project with frequent merge conflicts in shared files (e.g. a config file multiple people touch)|**High value**|
|Interactive rebase with many small commits touching overlapping lines|**High value** — this is the "6 identical conflicts in one rebase" case from the intuition section|

Since `webflyx` is currently solo work, `rerere` won't do much for you _yet_ — but it's a one-line config (`git config --global rerere.enabled true`) worth having on **permanently**, since it costs nothing when unused and silently saves real time the moment you hit a repetitive-conflict scenario (which becomes much more likely once Angular frontend + Spring Boot backend are both actively changing, or once you collaborate with others).

---

**One-line definition to remember:**

> `rerere` records how you resolved a conflict and automatically reapplies that exact resolution if the identical conflict pattern recurs — turning repeated manual conflict-resolution (common in long rebases or repeatedly-rebased branches) into a one-time task, while still pausing for your review before continuing.




[[0 - Git]]