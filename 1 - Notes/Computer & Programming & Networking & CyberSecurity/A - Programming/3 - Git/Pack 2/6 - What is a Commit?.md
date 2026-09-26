

A **commit** is a **permanent, immutable snapshot** of your entire project at a specific point in time, stored in Git's object database. It's not a "diff" or a "change" — it's a complete picture of what every tracked file looked like at that moment, linked to the commit(s) before it, forming a chain of history.

Each commit contains:

- A pointer to a **tree** (the full snapshot of the project)
- A pointer to its **parent commit(s)** (linking it into history)
- **Author** (who wrote the change) + **Committer** (who applied it — can differ)
- **Timestamp**
- A **commit message** describing _why_ the change was made
- A unique **SHA-1 hash** identifying it

> **Mental model:** A commit is a save point — like a checkpoint in a video game — that you can always return to, compare against, or branch off from.

---

## Rules for Writing Good Commits

|Rule|Why it matters|
|---|---|
|**One logical change per commit**|Makes history readable, easy to revert, easy to review — don't mix a bug fix with a refactor with a typo fix|
|**Write in the imperative mood**|`"Fix login bug"` not `"Fixed login bug"` or `"Fixes login bug"` — matches Git's own auto-generated messages (e.g. merge commits)|
|**Keep the subject line ≤ 50 characters**|Keeps `git log --oneline` and GitHub UI readable|
|**Leave a blank line, then a body if needed**|Explain _why_, not just _what_ — the diff already shows _what_ changed|
|**Don't commit broken code**|Every commit should ideally build/run — makes `git bisect` and rollbacks safe|
|**Don't commit unrelated files**|No stray debug files, no `.env` secrets, no build artifacts (use `.gitignore`)|
|**Commit often, push when ready**|Small, frequent commits locally are fine and encouraged — you can clean them up later with rebase before sharing|
|**Never rewrite public/shared history**|Once pushed and others may have pulled it, don't `amend`/`rebase` those commits — use `revert` instead|
|**Follow a consistent message convention**|e.g. **Conventional Commits**: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`|

**Example of a good commit message:**

```
fix: prevent crash when user token is expired

Previously, an expired token caused a null pointer exception
in AuthService. Now it triggers a re-authentication flow instead.
```

---

## When Should You Commit?

Commit when you reach a **logically complete, working unit of change** — not based on time, but based on meaning:

|Good time to commit|Bad time to commit|
|---|---|
|A single bug is fixed|Code is mid-edit and won't even compile|
|A small feature/function is complete and working|You've mixed 3 unrelated changes together|
|You're about to try something risky (commit first as a safety checkpoint)|You're "not sure yet" what the final change should look like (finish it first, or use `stash`)|
|Before switching branches/tasks|Right before pushing without reviewing the diff at all|
|After passing relevant tests|Never — waiting too long to avoid "cluttering history" (small commits are good!)|

**Rule of thumb:** _If you had to explain the commit in one sentence and it would need the word "and" more than once, it's probably two commits._

---

## Commit Commands

|Command|What it does|
|---|---|
|`git commit -m "message"`|Commit staged changes with an inline message|
|`git commit`|Opens your configured editor to write a (multi-line) message|
|`git commit -a -m "message"`|Skips staging — commits all changes to _already-tracked_ files (won't include new untracked files)|
|`git commit --amend`|Replaces the last commit with a new one (edit message and/or add more staged changes)|
|`git commit --amend --no-edit`|Adds staged changes to the last commit, keeping the same message|
|`git commit --amend --author="Name <email>"`|Changes the author of the last commit|
|`git commit -v`|Shows the diff inside the commit message editor for review while writing|
|`git commit --allow-empty -m "message"`|Creates a commit with no changes (rare use, e.g. triggering CI)|
|`git commit --no-verify`|Skips pre-commit/commit-msg hooks|
|`git log --oneline`|View commit history compactly|
|`git show <hash>`|Inspect one specific commit's full diff and metadata|
|`git log -1`|Show details of the most recent commit|

---

**One-line definition to remember:**

> A commit is an immutable, uniquely-identified snapshot of your project, representing one deliberate, logical unit of change in history.


---
```bash 
ethan@debian:/mnt/hdd/Home/Programming Files/Git/webflyx$ git push                                                                                   
To https://github.com/AlirezaAkhavanJava/webflyx.git                                                                                                                           

 ! [rejected]       main -> main (non-fast-forward)                                                                                                                           

error: failed to push some refs to 'https://github.com/AlirezaAkhavanJava/webflyx.git'                                                                                         

hint: Updates were rejected because the tip of your current branch is behind                                                                                                   

hint: its remote counterpart. If you want to integrate the remote changes,                                                                                                     

hint: use 'git pull' before pushing again.                                                                                                                                     

hint: See the 'Note about fast-forwards' in 'git push --help' for details.                                                                                                     

ethan@debian:/mnt/hdd/Home/Programming Files/Git/webflyx$
```

## What Happened

This is the classic "I amended a commit that was already pushed" situation. Let's break down exactly why:

1. You had already pushed a commit to `origin/main` (let's call it commit **A**)
2. You ran `git commit --amend --no-edit` — this didn't edit commit A, it **created a brand new commit** (commit **A'**) with the same content/message but a **different SHA-1 hash** (because amend always makes a new commit object — remember, commits are immutable!)
3. Your local `main` now points to **A'**, but `origin/main` still points to **A**
4. Git sees these as two _different, unrelated-looking_ histories that both branched from the same point → **diverged**

That's exactly what `git status` told you:

```
Your branch and 'origin/main' have diverged,
and have 1 and 1 different commits each, respectively.
```

Translation: "You have 1 commit remote doesn't have (A'), and remote has 1 commit you don't have (A) — even though they're really the 'same' change."

`git fetch` doesn't fix this — it just downloads remote's state so Git _knows_ about the divergence. It won't merge anything automatically.

---

## Why `git push` Keeps Failing

Because pushing is only allowed to be a **fast-forward** by default — meaning your local history must be a direct continuation of remote's history. Since you rewrote a commit remote already has, that's no longer true. Git is protecting you from silently discarding history other people (or other clones) might rely on.

---

## The Two Ways Out

### Option A — Force push (correct here, since you're the only one working on this)

Since `--amend` is _meant_ to rewrite history, and this is your own solo commit that (presumably) nobody else has pulled yet, this is the standard, expected fix:

```bash
git push --force-with-lease
```

**Why `--force-with-lease` instead of plain `--force`:**

- `--force` blindly overwrites whatever is on the remote — dangerous if someone else pushed something in the meantime
- `--force-with-lease` checks that the remote hasn't changed since your last fetch — refuses to push (safely) if someone else's work would get clobbered

This tells GitHub: "Yes, I intentionally rewrote history — replace A with A'."

### Option B — Don't force push; merge instead (if others may have pulled A)

If someone else might have already pulled the old commit A, forcing would break their local history too. In that case:

```bash
git pull   # merges remote's version with yours, creating a merge commit
git push   # now a normal fast-forward push works
```

But this creates a slightly messier history (a merge commit for what should've been a simple fix). For solo projects or commits nobody's pulled yet, **Option A is cleaner and standard practice.**

---

## The Rule to Remember

> **Never `amend` (or rebase) a commit that others may have already pulled — unless you're prepared to force-push and communicate that history changed.**

For your own solo branches/repos, amend + force-push is completely normal and expected. This is _exactly_ why `--force-with-lease` exists — it's the "safe" version of the rewrite-history workflow.

---

## In Your Specific Case

Since it's just you (`ethan`/`Alireza`) on this repo:

```bash
git push --force-with-lease
```



[[0 - Git 🍋‍🟩]]