
## `.gitignore` — Deep Dive

---

## Core Intuition First

Git, by default, wants to track **everything** in your working directory. But not everything _should_ be tracked — compiled output, IDE config, secrets, OS junk files, dependency folders. `.gitignore` is simply a **list of patterns telling Git: "don't even consider these files for tracking."**

> **Mental model:** `.gitignore` doesn't _remove_ or _hide_ files — it tells `git status`, `git add .`, and `git add -A` to **skip** matching files/folders as if they don't exist, for the purposes of staging. The files are still physically there on disk; Git just stops offering to track them.

---

## Why This Exists — The Problem It Solves

Without `.gitignore`, every `git status` in a Java/Spring Boot project would show you a wall of noise like:

```
target/
.idea/
*.class
application-local.properties
.DS_Store
```

Every time. You'd have to manually avoid `git add`-ing these every single commit, and one slip (`git add .` without thinking) would accidentally commit:

- **Build artifacts** (`target/`, `*.class`) — huge, regenerable, pollutes every diff
- **IDE-specific config** (`.idea/`, `.vscode/`) — personal to your editor, meaningless to teammates
- **Secrets** (`application-local.properties`, `.env`) — a genuine security risk if pushed to a public repo
- **OS junk** (`.DS_Store` on macOS, `Thumbs.db` on Windows)
- **Dependencies** (`node_modules/`, sometimes `.m2/` caches) — massive, regenerable from a manifest file (`pom.xml`, `package.json`)

`.gitignore` automates "never offer these as candidates for committing" so this becomes a non-issue, permanently, project-wide.

---

## How to Create One

Just a plain text file named exactly `.gitignore`, placed at your repo's root (or in any subfolder for localized rules):

```bash
touch .gitignore
```

---

## Pattern Syntax

|Pattern|Matches|
|---|---|
|`target/`|The folder named `target`, anywhere in the repo (trailing `/` = directory only)|
|`*.class`|Any file ending in `.class`, anywhere|
|`*.log`|Any file ending in `.log`|
|`/config.properties`|Only `config.properties` at the **repo root** (leading `/` anchors it)|
|`logs/*.log`|`.log` files directly inside a `logs/` folder (not nested deeper)|
|`logs/**/*.log`|`.log` files inside `logs/` at **any** depth (`**` = recursive wildcard)|
|`!important.log`|**Negation** — un-ignore a file that would otherwise match a broader pattern above it|
|`# comment`|Lines starting with `#` are comments, ignored by Git|
|`temp?.txt`|`?` matches exactly one character — matches `temp1.txt`, not `temp10.txt`|

### Order matters for negation

```
*.log
!important.log
```

This ignores all `.log` files **except** `important.log`. But negation **cannot** un-ignore a file inside an already-ignored _directory_ — if the parent folder itself is ignored, Git never even looks inside it to check for negation patterns. This trips people up constantly.

---

## A Real `.gitignore` for Your Spring Boot / Java Setup

```gitignore
# Compiled output
target/
*.class

# Maven
.mvn/wrapper/maven-wrapper.jar

# IDE
.idea/
*.iml
.vscode/

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Environment / secrets
application-local.properties
.env

# Spring Boot specific
*.pid
```

For Gradle-based Spring Boot instead of Maven, you'd add:

```gitignore
.gradle/
build/
!gradle/wrapper/gradle-wrapper.jar
```

---

## Crucial Gotcha: `.gitignore` Only Affects **Untracked** Files

This is the single most common point of confusion, so it's worth being precise about the mechanism.

If a file is **already tracked** (already committed at some point in the past), adding it to `.gitignore` **does nothing** — Git continues tracking it, because `.gitignore` only prevents _new_ files from being staged. It doesn't retroactively untrack anything.

### Fix: Untrack a file that was committed by mistake

```bash
git rm --cached <file>          # removes from Git's tracking, keeps it on your disk
echo "<file>" >> .gitignore      # now prevent it from being re-added in the future
git commit -m "stop tracking <file>"
```

For an entire folder:

```bash
git rm -r --cached target/
echo "target/" >> .gitignore
git commit -m "stop tracking target/"
```

**Why this behavior makes sense, mechanically:** remember from the object model — a tracked file exists as a blob, referenced by a tree, referenced by a commit. `.gitignore` is consulted only at the **working-directory-to-index** stage (when you `git add`). It has zero connection to what's already baked into historical tree objects. This is also why `.gitignore` can't "clean up" history — a secret committed once and later gitignored is still sitting in every past commit's tree, recoverable by anyone who clones the repo and checks older commits.

---

## Checking What's Actually Ignored

```bash
git status --ignored              # show ignored files explicitly
git check-ignore -v <file>        # shows EXACTLY which rule in which .gitignore is matching a file
```

`git check-ignore -v` is invaluable for debugging "why isn't this being ignored?" — it tells you the exact file and line number of the matching rule.

---

## Multiple `.gitignore` Files (Scoped Rules)

You can place a `.gitignore` in **any subdirectory**, not just the root — its rules apply only to that folder and below:

```
webflyx/
├── .gitignore              ← project-wide rules
├── frontend/
│   └── .gitignore           ← frontend-specific rules (e.g. node_modules/)
└── backend/
    └── .gitignore            ← backend-specific rules (e.g. target/)
```

Useful for monorepo-style structures with multiple sub-projects having different toolchains.

---

## Global `.gitignore` (Per-User, Not Per-Project)

Some ignores are about **your machine/editor**, not the project itself — e.g., `.DS_Store` or `.idea/` shouldn't need to be re-added to every single repo's `.gitignore` individually. Instead:

```bash
git config --global core.excludesfile ~/.gitignore_global
```

Then put machine-wide junk patterns in `~/.gitignore_global`:

```gitignore
.DS_Store
.idea/
*.swp
```

This keeps project-level `.gitignore` files clean and focused on things that matter to _everyone_ on the project (build artifacts, secrets), while your personal editor/OS junk lives separately.

---

## Related: `.gitattributes` (Quick Connection)

Worth knowing it exists alongside `.gitignore`, though it solves a different problem — `.gitattributes` doesn't decide _whether_ to track a file, it controls _how_ Git treats tracked files: line-ending normalization, marking files as binary, diff/merge behavior. Different tool, same spirit of "project-level rules file sitting at the repo root."

---

## Edge Case: Ignoring Everything Except Specific Files

A common pattern — ignore an entire folder, but whitelist a few files inside it:

```gitignore
folder/*
!folder/keep-this.txt
```

Note this only works because the pattern is `folder/*` (contents), not `folder/` (the folder itself as a unit) — ignoring the folder itself would make Git skip looking inside entirely, breaking the negation (same gotcha as before).

---

**One-line definition to remember:**

> `.gitignore` is a pattern-matching filter consulted only when staging new files — it prevents untracked files from ever becoming tracked, but has no power over files already committed, and no power over history once something's been pushed.




[[0 - Git]]