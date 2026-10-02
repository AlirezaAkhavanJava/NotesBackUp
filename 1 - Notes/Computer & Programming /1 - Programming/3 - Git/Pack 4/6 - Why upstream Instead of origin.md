

Because **`origin` and `upstream` point to two different repositories with two completely different purposes**, and you need both remotes simultaneously — not one instead of the other.

---

## The Actual Situation: You Need BOTH, Not One Or The Other

This isn't "use `upstream` instead of `origin`" — it's "you have `origin` **and** `upstream`, each doing a job the other can't."

```bash
git remote -v
```

```
origin    https://github.com/YourUsername/project.git     (your fork)
upstream  https://github.com/OriginalOwner/project.git     (the original)
```

||`origin`|`upstream`|
|---|---|---|
|What it is|**Your** fork|The **original** repo you forked from|
|Write access?|Yes|No (almost always)|
|You push here|Yes — this is where your commits go|Never (you can't, you don't have access)|
|You pull/fetch here|Rarely needed (it's your own fork, you already have your own commits)|**Yes — this is the whole point**|

---

## Why You Specifically Need `upstream`

Here's the problem `upstream` solves, concretely: **the original project keeps moving after you fork it.**

```
Day 1: You fork project at commit A
       OriginalOwner/project: A
       YourUsername/project:  A   (identical, just forked)

Day 30: OriginalOwner/project has moved on — other contributors added B, C, D
       OriginalOwner/project: A---B---C---D
       YourUsername/project:  A                (your fork is now 3 commits behind, frozen at day 1)
```

If you only had `origin` (your fork), you'd have **no way to ever find out** that B, C, D exist, let alone pull them into your fork. `origin` only talks to _your_ copy — it has no idea the original moved forward, because your fork is a completely separate repository as far as Git is concerned (recall from the fork deep-dive: Git itself doesn't even know "fork" is a concept — `origin` is just a URL).

`upstream` is how you **stay connected to the original's ongoing progress**:

```bash
git fetch upstream
git merge upstream/main     # bring B, C, D into your local main
git push origin main          # update your fork on GitHub to match
```

---

## Why This Matters Practically — Two Concrete Failure Modes Without `upstream`

### 1. Your Pull Request becomes outdated/conflicted

If you work on a feature branch for a while without ever syncing from `upstream`, and the original project has moved on significantly, your PR will likely have merge conflicts against the current `main` — because you branched off an old, stale version of the code.

### 2. You duplicate work or miss breaking changes

Without pulling from `upstream`, you won't know if someone else already fixed the bug you're working on, or if an API you're building against has changed. `upstream` is your only connection to "what's actually happening in the real project right now."

---

## Why Not Just Make `origin` Point to the Original Instead?

You might wonder: why not skip the fork entirely and just set `origin` to the original repo's URL?

```bash
git remote set-url origin https://github.com/OriginalOwner/project.git
```

Because then `git push` would try to push to the **original repo**, where you have no write access — right back to the permission-denied wall from the start of this topic. You need `origin` to remain **your fork** (where you _can_ push) while `upstream` remains the **original** (where you can only _read_). Swapping them would break the entire mechanism that makes forking work.

---

## The Naming Is Convention, Not Requirement (Worth Repeating)

Nothing forces you to name it `upstream` specifically — you could call it `original`, `source`, `root`, whatever. But `upstream` is the near-universal convention across the entire Git/GitHub ecosystem, so sticking with it means any collaborator (or any tutorial, or your future self in six months) immediately understands what that remote is for without needing explanation.

---

**One-line answer to remember:**

> You don't use `upstream` _instead of_ `origin` — you use `upstream` _in addition to_ `origin`, because `origin` (your fork, writable) is where you push your work, while `upstream` (the original, read-only) is your only way to stay in sync with a project that keeps evolving after you forked it.


[[0 - Git]]