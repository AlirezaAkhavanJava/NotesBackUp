

A **fork** is a **personal copy of someone else's entire remote repository**, created on a hosting platform like GitHub, GitLab, etc. It's not a native Git command/object at all — it's a **platform-level feature** (GitHub, GitLab, Bitbucket), not something `git` itself does.

> **Mental model:** Cloning copies a repo to your _local machine_. Forking copies a repo to _your own account on the server_ — a completely independent remote repository that you have full control over.

---

## Why Forking Exists — The Problem It Solves

If you want to contribute to someone else's open-source project, you almost never have **write access** to their repository. You can't just `git push` your changes to it.

**Forking solves this** by giving you your own copy of the repo — under your account — where you _do_ have full write access, so you can freely branch, commit, and push, without touching the original project at all.

---

## Fork vs. Clone

||**Clone**|**Fork**|
|---|---|---|
|What it copies|Repo → your local machine|Repo → a new remote repo under _your_ account|
|Where it lives|Your computer|GitHub/GitLab server (then you clone _that_)|
|Relationship to original|Just a local copy|An independent server-side repo, linked to the original|
|Write access needed|None to clone|None to fork — that's the whole point|
|Typical use|Any repo you want locally|Contributing to a repo you don't own|

---

## Typical Fork Workflow (Open Source Contribution)

```bash
# 1. Fork the repo on GitHub (via the web UI "Fork" button)
#    → creates https://github.com/YourUsername/project

# 2. Clone YOUR fork locally
git clone https://github.com/YourUsername/project.git

# 3. Add the original repo as a second remote (convention: "upstream")
git remote add upstream https://github.com/OriginalOwner/project.git

# 4. Make changes on a branch, commit, push to YOUR fork
git checkout -b fix-typo
git commit -m "fix: typo in README"
git push origin fix-typo

# 5. Open a Pull Request from your fork's branch → the original repo
#    (done via GitHub's web UI)

# 6. Keep your fork updated with the original project over time
git fetch upstream
git merge upstream/main
```

---

## Remotes in a Forked Setup

|Remote name|Points to|Purpose|
|---|---|---|
|`origin`|**Your** fork|Where you push your work|
|`upstream`|**Original** repo|Where you pull updates from, to stay in sync|

This `origin` + `upstream` naming pattern is a strong convention across the Git/GitHub world — worth memorizing.

---

**One-line definition to remember:**

> A fork is your own independent, writable remote copy of someone else's repository — used to contribute changes back via a Pull Request, without needing write access to the original.

Since you're on GitHub already (`AlirezaAkhavanJava`), want to walk through **actually forking and contributing to a small test repo** hands-on, so this workflow clicks?


[[0 - Git 🍋‍🟩]]