

Both are **refs** — pointers to a commit — but they behave very differently and solve different problems.

---

## Branch

A **movable** pointer to a commit, meant to represent an **active line of development**.

- Automatically moves forward every time you commit while on it
- Meant to change constantly
- Represents: _"work currently happening here"_

```
main → commit A → commit B → commit C   (branch pointer moves to C after each commit)
```

---

## Tag

A **fixed, permanent** pointer to one specific commit, meant to mark a **significant, unchanging point in history** — almost always a **release**.

- Never moves automatically (and generally shouldn't move at all)
- Represents: _"this exact commit = version 1.0"_
- Doesn't get "checked out and worked on" the way branches do

```
v1.0 → commit B   (stays pointing at B forever, even after main moves to C, D, E...)
```

---

## Key Differences Table

||**Branch**|**Tag**|
|---|---|---|
|Moves as you commit?|Yes — automatically|No — stays fixed|
|Purpose|Active development line|Marking a specific milestone (release)|
|Can you commit "on" it?|Yes|No (it's just a label, not a working line)|
|Stored at|`.git/refs/heads/`|`.git/refs/tags/`|
|Has its own commit history?|Yes, grows over time|No — always points to one fixed commit|
|Typical naming|`main`, `feature-login`, `dev`|`v1.0`, `v2.1.3`, `release-2026-09`|
|Pushed by default with `git push`?|Yes|**No** — tags need `git push --tags` explicitly|

---

## Two Types of Tags

### 1. Lightweight Tag

Just a name pointing directly at a commit — **not even a real Git object**, just a ref (like a simplified branch that never moves).

```bash
git tag v1.0
```

### 2. Annotated Tag (recommended for releases)

A **real Git object** (type: `tag`) containing tagger name, email, date, a message, and optionally a **GPG signature** for verification.

```bash
git tag -a v1.0 -m "First stable release"
```

```bash
git cat-file -p v1.0
```

```
object 9f8e7d6c5b4a3210...
type commit
tag v1.0
tagger Alireza <email> 1694000000 +0330

First stable release
```

> **Rule of thumb:** Use annotated tags for anything real (releases). Lightweight tags are fine for quick, throwaway local markers.

---

## Common Tag Commands

|Command|What it does|
|---|---|
|`git tag`|List all tags|
|`git tag v1.0`|Create a lightweight tag on current commit|
|`git tag -a v1.0 -m "msg"`|Create an annotated tag|
|`git tag -a v1.0 <commit-hash> -m "msg"`|Tag a _specific_ past commit, not just HEAD|
|`git show v1.0`|Show the tag's info + the commit it points to|
|`git tag -d v1.0`|Delete a local tag|
|`git push origin v1.0`|Push a single tag to remote|
|`git push --tags`|Push **all** local tags to remote|
|`git push origin --delete v1.0`|Delete a tag on the remote|
|`git checkout v1.0`|Check out the code at that tag (puts you in **detached HEAD**, since a tag isn't a branch you can commit on)|

---

## Common Branch Commands (Recap)

|Command|What it does|
|---|---|
|`git branch`|List local branches|
|`git branch <name>`|Create a new branch|
|`git switch <name>` / `git checkout <name>`|Switch to a branch|
|`git switch -c <name>`|Create + switch in one step|
|`git branch -d <name>`|Delete a branch (safe — only if merged)|
|`git branch -D <name>`|Force delete a branch (even if unmerged)|
|`git branch -m <old> <new>`|Rename a branch|
|`git push origin --delete <name>`|Delete a branch on the remote|

---

## Why This Distinction Matters in Practice

- **Branches** are for **process** — where ongoing work happens, gets reviewed, gets merged
- **Tags** are for **history markers** — "this is what shipped as v1.0," used for rollback reference, changelogs, deployment pipelines pulling a specific version

A very common real workflow: merge a feature branch into `main`, then once it's ready to ship, **tag** that exact commit as a release — the branch keeps moving forward with new work, while the tag stays frozen at that release point forever.

---

**One-line definitions to remember:**

> **Branch** = a movable pointer marking an active line of development.  
> **Tag** = a fixed pointer permanently marking one specific, significant commit — almost always a release version.




[[0 - Git 🍋‍🟩]]