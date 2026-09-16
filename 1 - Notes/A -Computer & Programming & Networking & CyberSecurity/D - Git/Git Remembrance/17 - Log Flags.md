
`git log` has a lot of options. The important thing is to understand that its flags control **what commits are shown**, **how they are selected**, and **how they are formatted**.

## 1. Basic `git log`

```bash
git log
```

Shows commits reachable from the current `HEAD`, newest first.

Typical output:

```text
commit a1b2c3d4...
Author: Alireza <...>
Date:   Wed Sep 16 20:20:00 2026 +0330

    Add user authentication
```

---

# 2. The most important `git log` flags

|Flag|Meaning|Example|
|---|---|---|
|`--oneline`|One line per commit|`git log --oneline`|
|`--all`|Show commits from all refs/branches|`git log --all`|
|`--graph`|Draw branch/merge graph|`git log --graph`|
|`--decorate`|Show refs pointing to commits|`git log --decorate`|
|`--stat`|Show changed-file statistics|`git log --stat`|
|`-p` / `--patch`|Show actual changes|`git log -p`|
|`--name-only`|Show changed filenames|`git log --name-only`|
|`--name-status`|Show filenames + change type|`git log --name-status`|
|`--abbrev-commit`|Shorten commit hashes|`git log --abbrev-commit`|
|`--pretty=<format>`|Customize commit display|`git log --pretty=full`|
|`--format=<format>`|Same idea as `--pretty`|`git log --format="%h %s"`|
|`--author=<pattern>`|Filter by author|`git log --author="Alireza"`|
|`--committer=<pattern>`|Filter by committer|`git log --committer="Alireza"`|
|`--grep=<pattern>`|Search commit messages|`git log --grep="security"`|
|`-i`|Case-insensitive matching|`git log -i --grep="SECURITY"`|
|`--invert-grep`|Exclude matching messages|`git log --invert-grep --grep="test"`|
|`-n`|Show only first N commits|`git log -5`|
|`--max-count=N`|Same as `-N`|`git log --max-count=5`|
|`--skip=N`|Skip first N commits|`git log --skip=5`|
|`--since=<date>`|Commits after date|`git log --since="2026-01-01"`|
|`--until=<date>`|Commits before date|`git log --until="2026-09-01"`|
|`--after=<date>`|Alias of `--since`|`git log --after="1 week ago"`|
|`--before=<date>`|Alias of `--until`|`git log --before="yesterday"`|

---

# 3. Branch/ref-related flags

These become **very important** when learning branches.

### `--all`

```bash
git log --all
```

Shows commits reachable from **all refs** known to Git, including branches.

Compare:

```bash
git log
```

Only follows the current `HEAD`.

```bash
git log --all
```

Looks across all refs.

A very useful command:

```bash
git log --oneline --graph --decorate --all
```

Example:

```text
* 8a91f22 (HEAD -> main) Add API
* 42bc123 Add repository
| * 9f31abc (feature/auth) Add JWT
| * 71ac222 Add security config
|/
* 12ab456 Initial commit
```

---

### `--branches`

```bash
git log --branches
```

Show commits reachable from local branches.

You can restrict it:

```bash
git log --branches=feature/*
```

---

### `--remotes`

```bash
git log --remotes
```

Show commits reachable from remote-tracking branches.

For example:

```text
origin/main
origin/dev
```

---

### `--tags`

```bash
git log --tags
```

Include commits reachable from tags.

---

### `--glob=<pattern>`

```bash
git log --glob='refs/heads/feature/*'
```

Select refs matching a pattern.

---

# 4. Graph visualization

### `--graph`

```bash
git log --graph
```

Draws ASCII lines showing ancestry.

Example:

```text
* commit A
| * commit B
| * commit C
|/
* commit D
```

Combining these is extremely useful:

```bash
git log --oneline --graph --decorate --all
```

I recommend memorizing this command.

---

# 5. Commit information formatting

### `--oneline`

Shortcut for approximately:

```bash
git log --pretty=oneline --abbrev-commit
```

Example:

```text
a91fd21 Add authentication
82ce331 Fix database connection
71ac222 Initial commit
```

---

### `--pretty`

Controls the format.

Common predefined formats:

```bash
git log --pretty=oneline
git log --pretty=short
git log --pretty=medium
git log --pretty=full
git log --pretty=fuller
git log --pretty=email
git log --pretty=raw
```

For example:

```bash
git log --pretty=fuller
```

shows both author and committer information.

---

### Custom format

This is one of the most powerful parts of `git log`.

```bash
git log --format="%h %an %ad %s"
```

Example:

```text
a91fd21 Alireza Wed Sep 16 20:20:00 2026 Add authentication
```

Important placeholders:

|Placeholder|Meaning|
|---|---|
|`%H`|Full commit hash|
|`%h`|Short commit hash|
|`%T`|Full tree hash|
|`%t`|Short tree hash|
|`%P`|Parent hashes|
|`%p`|Short parent hashes|
|`%an`|Author name|
|`%ae`|Author email|
|`%ad`|Author date|
|`%aD`|RFC2822 author date|
|`%ar`|Relative author date|
|`%cn`|Committer name|
|`%ce`|Committer email|
|`%cd`|Committer date|
|`%cr`|Relative committer date|
|`%s`|Subject|
|`%b`|Body|
|`%B`|Raw body|
|`%d`|Ref decorations|
|`%D`|Ref decorations without wrapping|

Very useful:

```bash
git log --format="%h %d %s"
```

---

# 6. Showing changes

### `-p`

```bash
git log -p
```

Show the patch introduced by each commit.

Example:

```diff
- String username;
+ String username;
+ String email;
```

This lets you see **what the commit actually changed**.

---

### `--stat`

```bash
git log --stat
```

Shows summary statistics.

Example:

```text
UserService.java | 12 ++++++++----
User.java        |  5 +++--
2 files changed, 11 insertions(+), 6 deletions(-)
```

---

### `--shortstat`

Only the final statistics:

```bash
git log --shortstat
```

---

### `--numstat`

Shows exact insertion/deletion counts:

```bash
git log --numstat
```

Example:

```text
12    4    User.java
8     2    UserService.java
```

---

### `--name-only`

```bash
git log --name-only
```

Shows filenames affected.

---

### `--name-status`

```bash
git log --name-status
```

Shows filenames plus status.

```text
M User.java
A UserService.java
D OldUser.java
```

Statuses:

|Letter|Meaning|
|---|---|
|`A`|Added|
|`M`|Modified|
|`D`|Deleted|
|`R`|Renamed|
|`C`|Copied|

---

# 7. Filtering by author

```bash
git log --author="Alireza"
```

Only commits whose **author** matches the pattern.

Regex is supported:

```bash
git log --author="Ali|Bob"
```

---

### `--committer`

```bash
git log --committer="Alireza"
```

Important distinction:

**Author** = person who originally wrote the change.

**Committer** = person who actually created the commit object.

They can be different.

---

# 8. Searching commit messages

### `--grep`

```bash
git log --grep="authentication"
```

Find commits whose commit message matches.

Example:

```text
a91fd21 Add JWT authentication
```

Multiple `--grep` expressions normally behave as OR unless combined with `--all-match`.

---

### `--all-match`

```bash
git log --grep="auth" --grep="JWT" --all-match
```

Commit message must match **all** patterns.

---

### `--invert-grep`

```bash
git log --invert-grep --grep="test"
```

Exclude commits whose messages match `test`.

---

### `-i`

```bash
git log -i --grep="AUTH"
```

Case-insensitive matching.

---

# 9. Date filtering

```bash
git log --since="2026-01-01"
```

Commits after that point.

```bash
git log --until="2026-09-01"
```

Commits before that point.

You can use natural language:

```bash
git log --since="2 weeks ago"
git log --since="yesterday"
git log --after="2026-09-01"
git log --before="2026-09-10"
```

Combine them:

```bash
git log --since="2026-09-01" --until="2026-09-16"
```

---

# 10. Limiting number of commits

### `-N`

```bash
git log -5
```

Show five commits.

Equivalent:

```bash
git log --max-count=5
```

---

### `--skip`

```bash
git log --skip=5
```

Skip five commits before displaying results.

Combine:

```bash
git log --skip=5 -5
```

Meaning:

> Skip the first 5, then show the next 5.

---

# 11. Following a file

One of the most useful commands when debugging history:

```bash
git log -- path/to/File.java
```

Example:

```bash
git log -- UserService.java
```

The `--` separates revisions/options from the path.

Meaning:

```text
git log [commits/options] -- [files]
```

---

### `--follow`

```bash
git log --follow -- UserService.java
```

Attempts to continue history across a file rename.

For example:

```text
OldUserService.java
        ↓ rename
UserService.java
```

`--follow` can trace the history before the rename.

It is primarily intended for a **single file**.

---

# 12. Finding commits by content

### `-S`

```bash
git log -S"JwtDecoder"
```

Find commits where the number of occurrences of the string changed.

This is called **pickaxe searching**.

Example:

```bash
git log -S"SecurityFilterChain" -- SecurityConfig.java
```

Useful question:

> "Which commit introduced or removed this exact code?"

---

### `-G`

```bash
git log -G"SecurityFilterChain"
```

Search commits whose **diff matches a regular expression**.

Difference:

```text
-S"text"
```

looks for a change in the number of occurrences.

```text
-G"regex"
```

looks for changed lines matching a regex.

This distinction is important.

---

# 13. Finding merge commits

### `--merges`

```bash
git log --merges
```

Show only merge commits.

---

### `--no-merges`

```bash
git log --no-merges
```

Hide merge commits.

---

# 14. First-parent history

### `--first-parent`

```bash
git log --first-parent
```

Only follows the first parent of each merge commit.

Very useful for seeing the **mainline history**.

Example:

```text
* Merge feature/auth
* Merge feature/api
* Merge feature/database
* Initial commit
```

Instead of diving into every individual feature commit.

---

# 15. Parent/ancestry filtering

### `--ancestry-path`

```bash
git log --ancestry-path A..B
```

Shows commits that are part of the ancestry path between A and B.

This becomes useful when analyzing complicated branch histories.

---

### `--boundary`

```bash
git log --boundary A..B
```

Shows boundary commits that are normally omitted by revision traversal.

They appear with a `-` marker in graph output.

---

# 16. Range notation with `git log`

This isn't technically a flag, but you **must** learn it with `git log`.

### `A..B`

```bash
git log A..B
```

Means:

> commits reachable from B but not reachable from A.

Example:

```bash
git log main..feature
```

Means:

> What commits does `feature` have that `main` does not?

---

### `A...B`

```bash
git log A...B
```

Means the symmetric difference between A and B.

Conceptually:

```text
commits unique to A
+
commits unique to B
```

Usually combined with:

```bash
git log --left-right A...B
```

---

### `--left-right`

```bash
git log --left-right main...feature
```

Shows which side each commit belongs to.

Example:

```text
< 91abc12 Main commit
> 72def34 Feature commit
```

`<` = left side (`main`)

`>` = right side (`feature`)

---

### `--cherry`

Useful when comparing branches whose commits may contain equivalent changes:

```bash
git log --left-right --cherry main...feature
```

Attempts to remove commits whose changes are equivalent even if their hashes differ.

---

# 17. Reference decorations

### `--decorate`

```bash
git log --decorate
```

Shows refs associated with commits.

Example:

```text
commit a91fd21 (HEAD -> main, origin/main)
```

Meaning both:

```text
HEAD -> main
origin/main
```

point to that commit.

---

### `--no-decorate`

Disable decorations.

---

### `--decorate=short`

```bash
git log --decorate=short
```

Shorter ref names.

---

# 18. Signature information

For signed commits:

```bash
git log --show-signature
```

Shows GPG/SSH signature information.

You can also use:

```bash
git log --format="%G? %GS %GK %s"
```

Some useful placeholders:

|Placeholder|Meaning|
|---|---|
|`%G?`|Signature status|
|`%GS`|Signer name|
|`%GK`|Signing key|
|`%GF`|Fingerprint|

---

# 19. Rename/copy detection

These are particularly relevant with `-p`.

```bash
git log -M
```

Detect renames.

```bash
git log -C
```

Detect copies.

More explicit:

```bash
git log -M90%
git log -C90%
```

Set similarity thresholds.

---

# 20. Reflog-related history

You can inspect reflog history with:

```bash
git log -g
```

or:

```bash
git log --walk-reflogs
```

This is extremely useful after things like:

```bash
git reset --hard
```

because normal commit history may no longer show where `HEAD` used to point.

Example:

```bash
git log -g --oneline
```

---

# 21. Pretty useful combinations

### A. See the entire repository graph

```bash
git log --oneline --graph --decorate --all
```

Memorize this one.

---

### B. Recent commits

```bash
git log --oneline -10
```

---

### C. Commits from a particular author

```bash
git log --author="Alireza" --oneline
```

---

### D. Search commit messages

```bash
git log --oneline --grep="authentication"
```

---

### E. History of one file

```bash
git log --oneline --follow -- UserService.java
```

---

### F. See exactly what changed

```bash
git log -p -- UserService.java
```

---

### G. Find when a piece of code appeared

```bash
git log -S"SecurityFilterChain" --oneline
```

---

### H. Compare branches

```bash
git log --oneline main..feature
```

---

### I. Compare both sides

```bash
git log --oneline --left-right main...feature
```

---

# 22. Useful advanced options

|Option|Purpose|
|---|---|
|`--reverse`|Show oldest commits first|
|`--date-order`|Don't show commits before all parents are shown|
|`--author-date-order`|Order based more strongly on author dates|
|`--topo-order`|Avoid showing commits in confusing ancestry order|
|`--no-walk`|Don't traverse history; only show specified commits|
|`--cc`|Combined diff for merge commits|
|`--full-history`|Don't simplify history|
|`--simplify-merges`|Simplify merge history|
|`--dense`|With history simplification, only show relevant commits|
|`--sparse`|Less aggressive history simplification|
|`--remove-empty`|Stop when a path becomes empty|
|`--relative-date`|Show dates relative to now|
|`--date=<format>`|Control date formatting|
|`--no-abbrev`|Don't shorten hashes|
|`--full-diff`|Show full diff for affected files|
|`--text`|Treat all files as text|
|`--ignore-space-change`|Ignore whitespace amount changes|
|`--ignore-all-space`|Ignore all whitespace|
|`--ignore-blank-lines`|Ignore changes involving blank lines|
|`--submodule`|Control submodule diff display|
|`--source`|Show which ref led to each commit|
|`--use-mailmap`|Resolve identities through `.mailmap`|
|`--encoding=<encoding>`|Display commit log using an encoding|

---

# 23. A mental model for `git log`

Think of the command as:

```text
git log
   │
   ├── WHERE?       → branches / refs / ranges
   │
   ├── WHICH?       → author / grep / dates / paths
   │
   ├── HOW MANY?    → -n / --skip
   │
   ├── WHAT DATA?   → -p / --stat / --name-only
   │
   └── HOW DISPLAY? → --oneline / --graph / --format
```

So this:

```bash
git log --oneline --graph --decorate --all --author="Alireza" --since="1 month ago"
```

can be read as:

> Search all refs → only Alireza's commits → from the last month → display one line each → draw the graph → show refs.

---

## The commands I'd memorize first

```bash
git log
git log --oneline
git log --oneline --graph --decorate --all
git log -p
git log --stat
git log --name-status
git log --author="..."
git log --grep="..."
git log --since="..."
git log -- path/to/file
git log --follow -- path/to/file
git log -S"someCode"
git log -G"regex"
git log --merges
git log --no-merges
git log --first-parent
git log main..feature
git log --left-right main...feature
git log -g
```

The **single most useful visualization** for your current branch-learning work is:

```bash
git log --oneline --graph --decorate --all
```

It connects directly to what you were just learning about `HEAD`, `refs/heads/main`, and `refs/remotes/origin/*`.



[[0 - Git 🍋‍🟩]]
[[0 - Git 65]]