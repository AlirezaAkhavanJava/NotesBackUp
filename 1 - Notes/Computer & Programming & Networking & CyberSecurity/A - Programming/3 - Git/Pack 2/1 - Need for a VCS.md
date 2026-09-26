## Why Do We Need a Version Control System (VCS)?

Imagine you're writing code alone or with a team. Without any tracking tool:

- You'd rename files like `project_final.js`, `project_final_v2.js`, `project_REAL_final.js` — total chaos.
- If you break something, you have no way to go back to a working version.
- If two people edit the same file, someone's work gets overwritten with no way to combine both changes.
- You have no record of _who_ changed _what_, _when_, or _why_.

A **Version Control System** is simply a tool that **tracks every change to your files over time**, so you can:

- See the full history of a project
- Go back to any previous version
- Work on new features without breaking the main code
- Let multiple people work on the same project without stepping on each other

---

## Types of VCS

There are three general categories, and they evolved in this order:

### 1. Local VCS

- History is stored in a simple local database, only on your own computer.
- Example: RCS (Revision Control System)
- **Problem**: Only works for one person, on one machine. No collaboration, no backup if your disk dies.

### 2. Centralized VCS (CVCS)

- One central server holds the _entire_ project history. People "check out" files from it and "commit" changes back to it.
- Examples: **CVS, Subversion (SVN), Perforce**
- **Improvement**: Multiple people could now collaborate, and there was one official source of truth.
- **Problem**: That one server is a single point of failure. If it crashes or gets corrupted, you could lose everything. You also need a network connection for almost every action.

### 3. Distributed VCS (DVCS)

- Every person clones the **entire repository, including all its history** — not just the latest files.
- Examples: **Git, Mercurial**
- **Improvement**: No single point of failure, everyone has a full backup, and most work can be done offline.

---

## Problems Before vs. After VCS (in general)

|Before VCS|After VCS|
|---|---|
|Manual file copies (`file_v1`, `file_v2_final`)|Automatic, structured history tracking|
|No way to undo mistakes reliably|Instant rollback to any previous state|
|Overwritten work when multiple people edit files|Merging tools combine changes safely|
|No record of who changed what|Full commit history with author, date, message|
|Hard to experiment safely|Branching lets you try things without risk|

---

## Git's Role: What Made It Special

Git is a **Distributed VCS**, but it specifically solved problems that even _earlier_ distributed and centralized systems struggled with:

|Old Problem (CVCS era)|Git's Fix|
|---|---|
|Central server = single point of failure|Every clone has the _complete_ history — a full backup|
|Needed network access for basic actions (commit, log, diff)|Everything happens locally — instant and offline-capable|
|Branching was slow/expensive, so people avoided it|Branches are cheap, lightweight pointers — creating one takes milliseconds|
|Merging was painful and rare|Git's merge tools and history tracking make merging routine and manageable|
|Hard to scale to thousands of independent contributors (e.g., open-source)|Anyone can clone and work independently, then propose changes back — no write access needed to start contributing|
|Data integrity wasn't guaranteed|Every piece of data is checksummed (SHA hash) — silent corruption is virtually impossible|

**In one sentence:** Git took version control from "a locked room you need permission to enter" to "everyone carries their own full copy of the building" — making it fast, safe, offline-friendly, and able to scale to massive, distributed teams like the Linux kernel project it was built for.



[[0 - Git 🍋‍🟩]]