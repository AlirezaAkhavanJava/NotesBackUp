
## Git Repository — Definition

A **Git repository** (or "repo") is a **directory that Git is tracking** — it contains your project's files _plus_ a hidden `.git` folder that stores the **entire history** of every change ever made: every commit, branch, tag, and the underlying data (file snapshots) that makes it all work.

In simple terms: **it's a project folder with a built-in time machine.**

---

## The Two Parts of a Repository

|Part|What it is|
|---|---|
|**Working directory**|The actual files you see and edit — your code, as it currently looks|
|**`.git` folder**|The hidden database holding all history, branches, commits, and configuration — this _is_ the repository, technically|

If you delete the `.git` folder, you still have your files — but you've lost all history. It's no longer a repository, just a plain folder.

---

## Two Ways a Repo Comes to Exist

1. **`git init`** — turns an existing folder into a new, empty Git repository (creates the `.git` folder there)
2. **`git clone <url>`** — copies an _existing_ repository (files + full history) from somewhere else (like GitHub) onto your machine

---

## Local vs. Remote Repository

- **Local repository** — lives on your own machine
- **Remote repository** — lives on a server (e.g., GitHub, GitLab) so people can share and sync work

They're not fundamentally different things — a remote repo is just another full copy, usually treated as the shared "source of truth" for a team.

---

**One-line definition to remember:**

> A Git repository is a directory whose complete history of changes is tracked and stored by Git, enabling versioning, branching, and collaboration.




[[0 - Git 🍋‍🟩]]