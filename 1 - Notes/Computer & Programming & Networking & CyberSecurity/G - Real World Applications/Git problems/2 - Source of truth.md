
**Source of truth (SoT)** means: the authoritative place or representation that defines what is correct. If another copy disagrees, you reconcile it to the source of truth; everything else is derived, cached, or a view.

### In programming generally
There isn’t one universal SoT — it depends on the domain:

- **Code behavior**: the version-controlled source files are the SoT. Binaries, bundles, generated code, and build artifacts are derived.
- **Runtime data**: the primary database or event log is the SoT. Caches, replicas, search indexes, and materialized views are derived.
- **Database schema**: migrations or a declarative schema are the SoT, not manual changes in a live DB.
- **Configuration/secrets**: a config repo or secrets manager is the SoT, not copied `.env` files or hardcoded values.
- **API contracts**: OpenAPI/protobuf/schema definitions are the SoT; generated clients and docs derive from them.
- **Dependencies**: a lockfile is the SoT for exact resolved versions.

So “source of truth” is usually per bounded context, not one single thing for the whole system.

### In Git
Technically, Git’s source of truth is the **repository object database**:

- **blobs** = file contents
- **trees** = directories
- **commits** = snapshots plus parents
- **tags** = named references to commits
- **refs** = branches, tags, `HEAD`, remote-tracking refs

These objects are content-addressed by SHA. The authoritative history is the **commit DAG reachable from an agreed ref** — usually something like `main` or a release tag.

What is *not* the source of truth in Git:

- **Working tree** = your current checkout; a mutable workspace.
- **Index/staging area** = a proposed next commit.
- **Local branch** = your local pointer/view.
- **`origin/main`** = your local remote-tracking ref, i.e. your last known view of the remote.

Practically, teams designate a canonical remote and branch — e.g. `origin/main` — as the source of truth. CI, releases, and merges treat that as authoritative. Local commits are proposals until they are pushed and merged into the canonical branch.

Because Git is distributed, **no clone is inherently more true than another**. Every clone has the full history. The “source of truth” is a social/operational convention: the canonical remote/branch that everyone agrees to integrate against. A merge, rebase, or PR updates that truth; a force-push to the canonical branch rewrites it.

**Short version:** in programming, the SoT is the authoritative code/data/config/schema store; in Git, it is the commit graph reachable from the agreed canonical ref/remote — not your working directory or local edits.


[[0 - Git]]