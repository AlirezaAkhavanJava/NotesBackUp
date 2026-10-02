
## What is Git?

Git is a **distributed version control system (VCS)** — a tool that tracks changes to files over time, so you can see history, revert mistakes, work on parallel versions of a project, and merge changes back together.

"Distributed" is the key word: every person who clones a repository gets the **entire history** on their own machine — not just the current files. There's no single central server required for it to function; everyone has a full, independent copy of the project's history.

Git was created by **Linus Torvalds in 2005** to manage development of the Linux kernel.

---

## The Problem Git Solved

Before Git, most teams used **centralized version control systems** (like CVS or Subversion/SVN). These had serious pain points:

|Problem|Why it hurt|
|---|---|
|**Single point of failure**|One central server held the _only_ full history. If it went down or got corrupted, you lost everything (or were stuck).|
|**Slow operations**|Every commit, diff, or log lookup required a network round-trip to the central server.|
|**No offline work**|You couldn't commit, branch, or view history without a network connection.|
|**Painful branching/merging**|Branching was expensive and merging was often a nightmare, so teams avoided it — leading to long-lived, conflict-heavy integration periods.|
|**Scaling to huge, distributed contributor bases**|Linux kernel development involves thousands of contributors worldwide, many without direct write access to a central repo. Centralized systems couldn't handle that model of collaboration well.|

### How Git specifically fixed this:

1. **Full local history** — every clone is a complete backup; no single point of failure.
2. **Fast operations** — commits, diffs, branch switches all happen locally, instantly, no network needed.
3. **Cheap, fast branching & merging** — branches are just lightweight pointers to commits, not full copies. This made branching a _core habit_ instead of a rare event.
4. **Content-addressable storage** — Git identifies data by the SHA-1 hash of its content, not by filename/location, which makes integrity checking and deduplication natural.
5. **Decentralized collaboration model** — anyone can clone, work independently, and propose changes back (via patches or pull requests) without needing write access to a "central" repo — perfect for open-source projects like Linux with a massive, distributed contributor base.

In short: **Git solved the problem of collaborating on code at scale — reliably, offline-capable, and without a fragile central bottleneck.**

---

## Key Features

- **Branching and Merging**: Create isolated branches for features or fixes, then merge them back into the main codebase.
- **Commit History**: Tracks changes with detailed logs, allowing users to revert to previous versions.
- **Distributed Workflow**: Each developer has a full repository copy, reducing reliance on a central server.
- **Collaboration Tools**: Supports conflict resolution and team workflows through pull requests or merge requests.

## Common Commands

- `git init`: Create a new repository.
- `git clone`: Copy a repository.
- `git add`: Stage changes for commit.
- `git commit`: Save changes to the repository.
- `git push`: Upload changes to a remote repository.
- `git pull`: Fetch and merge changes from a remote repository.

[[Java]] [[0 - Back-End]]