

## 1. Core intuition

You can't eliminate conflicts, but you can make them **rare and small**. Imagine two people editing the same document:

- **Live, in a shared editor**, each sees the other's changes seconds after they happen. Collisions are tiny and obvious.
- **Offline, for two weeks**, each returns with a pile of edits, and some overlap in ways neither expected.

Git conflicts work the same way. Two levers control them:

```
conflict risk  ≈  how long branches stay apart  ×  how much they touch the same lines
```

1. **Reduce divergence time** (integrate often, keep branches short-lived).
2. **Reduce overlap** (structure code and work so people rarely edit the same lines).
3. **Remove artificial conflicts** (formatting noise, line endings, generated files).
4. **Make the unavoidable ones cheap** (tooling that remembers resolutions).

## 2. Why this works: the mechanics

From the merge model: Git compares your branch and theirs against the **merge base**, and a conflict happens only when changes overlap or touch (no unchanged line between them).

- A **longer-lived branch** means the base gets older, and both sides accumulate more hunks, so more chances to collide.
- **Hotspot files** (one giant class everyone edits) multiply the chance that two hunks land in the same region.
- **Noise changes** (reformatting, reordered imports, CRLF vs LF) create huge hunks that overlap with everything.

Every technique below attacks one of these three.

## 3. Process: reduce time apart

**Keep branches short-lived.** Aim for hours or a couple of days, not weeks. Conflict size grows faster than linearly with branch age.

**Integrate `main` into your branch often.** A tiny conflict today beats a huge one later.

```bash
git fetch
git merge origin/main          # or: git rebase origin/main (only for unshared branches)
```

**Small, focused pull requests.** A 50-line PR touches fewer files and merges before anything else drifts. Split work: one PR for the refactor, another for the behavior change.

**Trunk-based development with feature flags.** For large features, merge unfinished code into `main` early, hidden behind a flag, instead of keeping a big branch alive for weeks:

```java
@Service
public class TaskService {

    @Value("${features.task-priority:false}")
    private boolean taskPriorityEnabled;

    public Task create(TaskRequest req) {
        Task task = mapper.toEntity(req);
        if (taskPriorityEnabled) {
            task.setPriority(req.priority());
        }
        return taskRepository.save(task);
    }
}
```

Trade-off: flags add temporary complexity, so remove them once the feature ships.

**Merge queues / "require branch up to date" on GitHub or GitLab.** These force each PR to be tested against the _latest_ `main`, preventing two individually fine PRs from combining badly.

## 4. Process: reduce overlap between people

- **Talk before touching shared files.** A message like "I'm reworking `SecurityConfig` today" avoids a collision no tool can fix.
- **Divide work by area, not by task type.** One person on `billing`, another on `notifications`, rather than both "fixing bugs" across everything.
- **Use `CODEOWNERS`** so changes to sensitive files get routed to the right reviewer and ownership becomes visible.
- **Avoid mass changes mid-sprint**: package renames, global reformatting, and dependency-wide upgrades touch everything and conflict with everyone. Do them at a quiet moment and announce them.
- **Separate refactors from behavior changes.** A rename combined with a rewrite defeats Git's rename detection (roughly 50% similarity needed), turning a file into "deleted + added" and producing confusing conflicts.

## 5. Code structure: give people different places to edit

Git sees lines, so the shape of your code decides how often edits collide.

**Prefer small, cohesive classes** over one `TaskService` with 2,000 lines. If five features each live in their own class, five developers rarely touch the same file.

**Make "additions" not touch shared lines.** Classic Spring Boot hotspot, constructor injection:

```java
// Every new dependency edits the SAME lines → constant conflicts
private final TaskRepository taskRepository;
private final AuditLog auditLog;

public TaskService(TaskRepository taskRepository, AuditLog auditLog) {
    this.taskRepository = taskRepository;
    this.auditLog = auditLog;
}
```

If two branches each add a dependency, both edit the constructor signature and body. One fix is Lombok:

```java
@Service
@RequiredArgsConstructor
public class TaskService {
    private final TaskRepository taskRepository;   // one line per dependency
    private final AuditLog auditLog;               // adding one = adding one line
}
```

Each dependency is a single independent line, and the constructor isn't hand-written, so there's nothing for two branches to fight over. (Two branches adding lines at the _same_ spot can still conflict, but it's a trivial "keep both.") This is a trade-off, since some teams prefer explicit constructors for readability, but it demonstrably reduces churn.

**One item per line, in append-friendly layouts.**

```java
// Conflict-prone: everything on one line
public enum Status { TODO, DOING, DONE }

// Better: one constant per line, trailing semicolon style
public enum Status {
    TODO,
    DOING,
    DONE;
}
```

The same idea applies to lists in config, method arguments (one per line), and builder chains.

**Split configuration.** One enormous `application.yml` is a hotspot. Instead:

- Use profile files: `application-dev.yml`, `application-prod.yml`.
- Break related properties into `@ConfigurationProperties` classes, each with its own prefix, so changes to mail settings and security settings are separate edits.
- Use `spring.config.import` to pull in separate files by concern.

**`pom.xml`:** dependency blocks are a frequent conflict site. Keep entries alphabetized or grouped consistently, put versions in `<properties>` or a BOM, and avoid reformatting the file in unrelated PRs.

**Flyway/Liquibase migrations: a conflict Git can't see.** Two branches each add `V3__...sql` with different file names. Git merges cleanly, then the app crashes at startup due to duplicate version 3. Use timestamp-based versions so collisions are unlikely:

```
V20261003_1432__add_task_priority.sql
V20261004_0915__add_due_date.sql
```

If migrations can land out of order, Flyway needs `spring.flyway.out-of-order=true`, and CI should run migrations against a fresh database on every PR.

## 6. Remove artificial conflicts: formatting and line endings

These are conflicts of **noise**, not meaning, and the cheapest to eliminate.

**Shared formatter, enforced automatically.** If one person's IDE reformats whole files, their diff overlaps everyone else's. Pick one (google-java-format, or Spotless) and enforce it in the build:

```xml
<plugin>
  <groupId>com.diffplug.spotless</groupId>
  <artifactId>spotless-maven-plugin</artifactId>
  <configuration>
    <java>
      <googleJavaFormat/>
      <removeUnusedImports/>
    </java>
  </configuration>
</plugin>
```

```bash
./mvnw spotless:apply    # format
./mvnw spotless:check    # fail CI if not formatted
```

**Introduce a formatter in its own commit, at a quiet time**, then add that commit to `.git-blame-ignore-revs` so blame stays useful:

```bash
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

**Imports:** disallow wildcard imports (`import java.util.*;`) and use a fixed import order. Import blocks at the top of a file are one of the most common conflict sites.

**Line endings.** Mixed CRLF/LF makes entire files look changed. Add a `.gitattributes`:

```
* text=auto
*.sh text eol=lf
*.bat text eol=crlf
```

And a `.editorconfig` so every IDE agrees on indentation and newline style.

**Don't commit generated or build files.** `target/`, `.idea/`, `*.class`, and lock/derived files belong in `.gitignore`. Generated files conflict constantly and the conflicts are meaningless, since they can be regenerated.

## 7. Git settings that reduce or cheapen conflicts

```bash
git config --global rerere.enabled true         # remember how you resolved a conflict and replay it
git config --global merge.conflictStyle zdiff3  # show the base version in markers (diff3 on older Git)
git config --global pull.ff only                # git pull never creates surprise merge commits
git config --global diff.algorithm histogram    # often makes saner hunks when code was moved
```

- **`rerere`** is invaluable if you rebase a long branch repeatedly: you resolve each unique conflict once.
- **`merge=union` in `.gitattributes`** for _append-only_ files (a changelog, a list of entries) keeps both sides' lines automatically. Use it narrowly, since on code or `pom.xml` it can produce garbage:

```
CHANGELOG.md merge=union
```

- **Rebase vs merge:** rebasing your _own, unpublished_ branch onto `main` keeps history linear and surfaces conflicts early, but it can mean resolving the same conflict at several commits (squash first, or use `rerere`). Never rebase a branch others are using, because it rewrites shared history.

## 8. Predict conflicts before they bite

Check if a merge would conflict **without changing anything**:

```bash
git merge-tree --write-tree main feature     # Git 2.38+: simulates the merge in memory
```

It prints the resulting tree hash if clean, or lists the conflicted files if not, and leaves your working tree untouched.

An older equivalent that does touch your tree but is trivially reversible:

```bash
git merge --no-commit --no-ff origin/main    # try it
git merge --abort                            # undo it
```

Also useful for planning: `git diff --name-only main...feature` lists files your branch changes, so you can compare with a teammate's list and spot overlap early.

## 9. Gotchas and honest limits

- **Prevention isn't free.** Integrating often means _more frequent, smaller_ conflicts. That's a good trade, but not zero effort.
- **No conflict does not mean correct.** Git cannot see semantic conflicts, such as one branch renaming a repository method while another adds a caller of the old name, or duplicate Flyway versions. Run the build and tests on the merge result, ideally in CI with a merge queue.
- **Some conflicts are a signal, not a nuisance.** If two people keep colliding in the same file, the real fix may be splitting that class or clarifying ownership.
- **Over-fragmenting hurts.** Hundreds of tiny classes just to dodge conflicts harms readability. Aim for cohesion first.
- **Huge formatting passes backfire** if they happen while other branches are open. Coordinate so everyone merges or rebases right after.
- **Long-lived release branches** are legitimately long-lived. There, conflicts come from backporting; cherry-pick small, isolated fixes and keep release branches minimal.

## 10. Quick reference

|Cause of conflicts|Prevention|
|---|---|
|Branch lived too long|Short-lived branches, merge/rebase from `main` daily|
|Big PRs touching many files|Small, focused PRs; separate refactors from features|
|Same hotspot file|Split classes/config; `@RequiredArgsConstructor`; one item per line|
|Formatting or import noise|Enforced formatter, import order, `.editorconfig`|
|CRLF vs LF|`.gitattributes` with `* text=auto`|
|Generated files|`.gitignore`, don't commit them|
|Same migration number|Timestamp-based Flyway versions, CI against a fresh DB|
|Repeated conflicts in rebase|`rerere`, or squash before rebasing|
|Two people unaware of each other|Communicate, ownership, draft PRs|
|Unknown risk|`git merge-tree --write-tree` or `--no-commit` trial|

## 11. A daily habit that does most of the work

```bash
git switch feature/my-work
git fetch
git merge origin/main        # or rebase, if the branch is yours alone
./mvnw -q test               # confirm it still builds and passes
# ...keep working, push small PRs, merge quickly
```





[[Git & Github]]