

---

## Core Intuition First

A **monorepo** (mono = single, repo = repository) is a strategy where **multiple, often independently-deployable projects live inside one single Git repository**, instead of each project getting its own separate repo.

> **Mental model:** Instead of `webflyx-backend` and `webflyx-frontend` being two separate repos you clone separately, they'd both live inside one `webflyx/` repo, as sibling folders, sharing one unified commit history.

```
webflyx/                    ← ONE repo, ONE .git folder, ONE commit history
├── backend/                  (Spring Boot)
├── frontend/                  (Angular)
└── shared/                     (shared types, configs, docs)
```

This is directly relevant to you — you're building a Spring Boot backend with Angular as the front-end, and the nested-`.gitignore` topic we just covered was quietly setting up exactly this structure.

---

## Monorepo vs Polyrepo — The Fundamental Trade-off

||**Monorepo** (one repo, multiple projects)|**Polyrepo** (separate repo per project)|
|---|---|---|
|Commit history|Unified — one commit can touch backend + frontend together|Fragmented — a related change needs separate commits/PRs in each repo|
|Dependency versioning|Easy to keep in sync (frontend always matches backend's current API)|Risk of drift — frontend repo might reference an outdated backend API version|
|Clone size|Grows large over time, everyone clones everything|Each clone stays small, scoped to just that project|
|Access control|Harder to restrict — everyone with repo access sees everything|Easy to restrict per-project|
|Tooling complexity|Needs careful `.gitignore`/CI scoping (what we just covered)|Simpler per-repo, but duplicated setup across repos|
|Atomic cross-project changes|Trivial — one commit, one PR, changes both sides together|Painful — requires coordinating merges across multiple repos/PRs|
|Famous real-world examples|Google (famously, nearly their _entire_ codebase), Facebook/Meta, early-stage startups|Most small-to-medium companies, most open-source projects|

---

## Why a Monorepo Makes Sense for You Specifically

Your `webflyx` project — Spring Boot backend + Angular frontend — is a textbook case where a monorepo pays off, for a concrete reason tied directly to something you'll hit constantly: **the API contract between backend and frontend changes together.**

If you change a Spring Boot REST endpoint's response shape, your Angular service that calls it needs to change **in the same logical unit of work**. In a monorepo:

```bash
git commit -m "feat: add pagination to /api/movies endpoint + update Angular service"
```

One commit, one clear record that these changes are linked, easy to `git log` and understand later, easy to revert both sides together if something breaks.

In a polyrepo, this would be two separate commits in two separate repos, with no structural link between them — you'd have to rely on commit messages or external tracking (like a shared ticket number) to know they're related.

---

## Making It Work — The Structural Pattern (Building on Nested `.gitignore`)

This is where everything from the last several topics converges into one coherent setup:

```
webflyx/
├── .gitignore                 ← root: OS junk, .idea/, editor config
├── backend/
│   ├── .gitignore               ← target/, *.class
│   ├── pom.xml
│   └── src/
├── frontend/
│   ├── .gitignore                ← node_modules/, dist/, .angular/
│   ├── package.json
│   └── src/
└── README.md                      ← documents the whole-project structure
```

Each sub-project's `.gitignore` is scoped correctly (as covered), and the root `.gitignore` handles only genuinely shared, project-wide concerns.

---

## The Real Challenges Monorepos Introduce (Nuances/Gotchas)

### 1. Everyone Clones Everything

Unlike polyrepo, there's no way to clone _just_ the backend without also pulling the frontend's full history and files (not true in advanced setups — see sparse-checkout below — but true by default).

### 2. CI/CD Needs Path-Awareness

If you push a backend-only change, you don't want CI to waste time rebuilding/retesting the frontend too. This requires your CI config (GitHub Actions, GitLab CI) to detect **which folder changed** and run only the relevant pipeline:

```yaml
# conceptual example — GitHub Actions
on:
  push:
    paths:
      - 'backend/**'
```

### 3. Commit History Gets Noisy

`git log` on the whole repo mixes backend and frontend commits together. Mitigated with path-scoped log:

```bash
git log -- backend/              # only commits that touched backend/
git log -- frontend/              # only commits that touched frontend/
```

### 4. Large Repo Growth Over Time

Remember from the object-storage topic — `.git` size scales with history, not current content. Two active sub-projects generating commits means the repo's history grows from both sides simultaneously, faster than either would alone.

---

## Advanced Tooling: `sparse-checkout` (Solving "Everyone Clones Everything")

For genuinely large monorepos (think: Google-scale, or just a growing team), Git supports checking out **only part of the working directory**, while still being one logical repo with full shared history:

```bash
git clone --no-checkout <url>
cd webflyx
git sparse-checkout init --cone
git sparse-checkout set backend
```

This gives you the full `.git` history (so commits, blame, log all still work normally), but your **working directory** only materializes the `backend/` folder — frontend files simply don't exist on disk for you. A frontend-only developer could do the inverse.

This is genuinely advanced/optional — worth knowing it exists, not something you need for a two-person or solo project like `webflyx` currently.

---

## Monorepo vs. Git Submodules — A Distinction Worth Making Explicit

This connects to something briefly mentioned in the original roadmap (submodules, topic #44) — worth clarifying how they differ, since both deal with "multiple projects, one place."

||**Monorepo**|**Submodules**|
|---|---|---|
|Structure|One repo, one history, folders are just folders|Multiple **separate** repos, one "parent" repo that references specific commits of the others|
|Commit history|Fully unified|Each submodule keeps its own independent history|
|Complexity|Simpler day-to-day (`git add`, `git commit` work normally across everything)|Notoriously fiddly — forgetting to `git submodule update`, detached HEAD inside submodules, etc.|
|Use case|Tightly coupled projects that evolve together (your backend+frontend)|Genuinely independent projects that happen to be _included_, like a shared library maintained separately|

**For your case specifically:** monorepo is the right call, not submodules — your Angular frontend and Spring Boot backend aren't independent projects you're "including," they're two halves of one product evolving together. Submodules would add real friction (two separate commit histories to manage) for no real benefit here.

---

## Practical Setup Recommendation for `webflyx`

Given everything covered:

```bash
cd webflyx
mkdir backend frontend
# move/create Spring Boot project into backend/
# later: ng new frontend (or move existing Angular project in)
```

Root `.gitignore`:

```gitignore
.idea/
.DS_Store
*.log
```

`backend/.gitignore`:

```gitignore
target/
*.class
application-local.properties
```

`frontend/.gitignore` (once Angular's set up):

```gitignore
node_modules/
dist/
.angular/
```

From here, every commit can naturally span both sides when a change genuinely touches both — e.g., adding a new feature that needs both a new endpoint and a new Angular component — while `git log -- backend/` and `git log -- frontend/` let you review each side's history independently when needed.

---

**One-line definition to remember:**

> A monorepo keeps multiple related projects in one Git repository with one unified history — ideal when the projects evolve together (like your backend/frontend), at the cost of needing deliberate scoping (nested `.gitignore`, path-aware CI, `git log -- <path>`) to keep things organized as it grows.




[[0 - Git]]