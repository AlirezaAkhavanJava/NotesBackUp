

## 1. Core intuition

Two chefs each get a photocopy of the same recipe card. While you're apart, Chef A changes "bake 20 min" to "bake 25 min", and Chef B changes the same line to "bake 30 min". When you reunite, you can't tell which is right, because it's a judgment call about intent. A different line on the card, say B adding a garnish step, is no problem: only B touched it, so you keep it.

That is a merge conflict. **Git merges mechanically. When it cannot decide mechanically whose change should win, it stops and hands the decision to a human.** A conflict is Git being honest about the limits of its knowledge, not an error.

Two consequences follow:

1. Git is **line-based and language-blind**. It has no idea what a method, a class, or a Spring bean is. It sees lines of text.
2. A merge with **no** conflict can still be wrong (section 7), and a conflict is often easy once you understand both intentions.

## 2. The mental model: three versions, two diffs

Git never compares "mine" against "theirs" directly. That would only tell you they differ, not who changed what. Instead it uses three versions:

```
          BASE  (merge base: the last commit both branches share)
         /     \
      OURS     THEIRS
   (your branch) (branch being merged in)
```

It computes two diffs, **base→ours** and **base→theirs**, and then combines them hunk by hunk:

|What happened to a region|Result|
|---|---|
|Only ours changed it|Take ours|
|Only theirs changed it|Take theirs|
|Both changed it **identically**|Take it once, no conflict|
|Both changed it **differently**|**Conflict**|
|One deleted it, the other modified it|**Conflict** (modify/delete)|

**What counts as "the same region"?** Overlapping or **touching** line ranges. If you change line 10 and they change line 11, with no untouched line between them, Git treats that as a conflict. If there is at least one unchanged line between the edits, the two changes merge cleanly. This explains the otherwise puzzling case where "we edited different lines and still got a conflict."

```
line 8   unchanged
line 9   unchanged
line 10  ours edits
line 11  theirs edits   → touching hunks: CONFLICT
line 12  unchanged
```

## 3. Anatomy of a conflict

### The markers

```java
<<<<<<< HEAD
    private static final int MAX_RETRIES = 3;
=======
    private static final int MAX_RETRIES = 5;
>>>>>>> feature/retry-policy
```

- Top block (`<<<<<<<` to `=======`) is **ours**, the branch you're on.
- Bottom block (`=======` to `>>>>>>>`) is **theirs**, labeled with the incoming branch or commit.

### Show the base too (do this once, permanently)

```bash
git config --global merge.conflictStyle zdiff3   # Git 2.35+; use diff3 on older versions
```

```java
<<<<<<< HEAD
    private static final int MAX_RETRIES = 3;
||||||| parent of 4fa2c1e
    private static final int MAX_RETRIES = 2;
=======
    private static final int MAX_RETRIES = 5;
>>>>>>> feature/retry-policy
```

Now you see that the base was `2`, so **both** sides raised it. Without the base section, you'd only see two numbers and have to guess. This setting is the biggest single improvement to conflict resolution, because it lets you reason about _intent_, which is the whole job.

### What Git actually stores during a conflict

The index temporarily holds **three versions** of each conflicted file ("stages"):

|Stage|Contents|
|---|---|
|1|Base|
|2|Ours|
|3|Theirs|

```bash
git ls-files -u              # list unmerged entries with their stage numbers
git show :1:src/.../Foo.java # base version
git show :2:src/.../Foo.java # ours
git show :3:src/.../Foo.java # theirs
```

The marked-up file in your working directory is just a _rendering_ of those three. When you run `git add Foo.java`, you collapse the three stages into a single stage-0 entry, which is how you tell Git "this is resolved." **Git does not check that the markers are gone.** If you `git add` a file that still contains `<<<<<<<`, Git commits it happily. Guard against that:

```bash
git diff --check     # flags leftover conflict markers and whitespace errors
```

Merge state is also tracked on disk: `.git/MERGE_HEAD` (the commit being merged in), `.git/MERGE_MSG` (the prepared message), and `.git/MERGE_MODE`. That is how `git merge --continue` and `git merge --abort` know what to do.

### Reading `git status` labels

|Status|Meaning|
|---|---|
|`both modified`|Classic content conflict|
|`both added`|Both branches created a file at the same path with different content|
|`deleted by us` / `deleted by them`|One side deleted, the other modified|
|`added by us` / `added by them`|Often rename-related|
|`both deleted`|Rare; both renamed or removed it in different ways|

## 4. Worked example: Spring Boot constructor injection

This is the most common real conflict in a Spring project. The base:

```java
@Service
public class TaskService {

    private final TaskRepository taskRepository;

    public TaskService(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }
}
```

On `main`, someone adds email notifications. On your `feature/audit`, you add audit logging. You merge `main` into your branch:

```java
@Service
public class TaskService {

    private final TaskRepository taskRepository;
<<<<<<< HEAD
    private final AuditLog auditLog;

    public TaskService(TaskRepository taskRepository, AuditLog auditLog) {
        this.taskRepository = taskRepository;
        this.auditLog = auditLog;
    }
=======
    private final EmailService emailService;

    public TaskService(TaskRepository taskRepository, EmailService emailService) {
        this.taskRepository = taskRepository;
        this.emailService = emailService;
    }
>>>>>>> main
}
```

**Neither side is "right".** Both are additions that should coexist. This is the pattern: conflicts from independent additions in the same spot (imports, fields, constructor params, `pom.xml` dependencies, enum constants, entries in a list) need you to **combine**, not choose:

```java
@Service
public class TaskService {

    private final TaskRepository taskRepository;
    private final AuditLog auditLog;
    private final EmailService emailService;

    public TaskService(TaskRepository taskRepository,
                       AuditLog auditLog,
                       EmailService emailService) {
        this.taskRepository = taskRepository;
        this.auditLog = auditLog;
        this.emailService = emailService;
    }
}
```

Then the part people forget: **every place that constructs `TaskService` by hand now has the wrong arity.** Unit tests doing `new TaskService(repo)` or `new TaskService(repo, audit)` will fail to compile. Git can't know. The conflict resolution is only complete once the project builds and the tests pass.

### The resolution session

```bash
git switch feature/audit
git merge main                       # CONFLICT in TaskService.java
git status                           # see what's conflicted
# edit the file, remove markers, combine
git diff --check                     # no leftover markers?
./mvnw -q test                       # does it compile and pass?
git add src/main/java/.../TaskService.java
git merge --continue                 # finalize the merge commit
```

Bailing out at any point before `--continue`: `git merge --abort`.

## 5. Reading the combined diff

While conflicted, plain `git diff` shows a **combined diff** with two columns instead of one:

```
++<<<<<<< HEAD
 +    private final AuditLog auditLog;
++=======
+     private final EmailService emailService;
++>>>>>>> main
```

Column 1 compares the file against **ours** (stage 2), column 2 against **theirs** (stage 3). A `+` in a column means "this line isn't in that parent." A line with `+` in both columns is new relative to both, which is what a hand-written resolution looks like. Once you internalize this, `git diff` becomes a useful way to confirm you actually combined the two sides instead of picking one.

## 6. Taking a whole side, and redoing a botched resolution

```bash
git checkout --ours   -- path/File.java   # take our entire version of the file
git checkout --theirs -- path/File.java   # take their entire version
# modern equivalents:
git restore --ours path/File.java
git restore --theirs path/File.java

# You mangled the file and want the original conflict markers back:
git checkout --merge -- path/File.java    # or: git restore --merge path/File.java
git checkout --conflict=diff3 -- path/File.java   # re-create with base shown
```

Whole-file `--ours`/`--theirs` discards **all** of the other side's changes to that file, including parts that merged cleanly. Use it for binaries and for files where you genuinely want one side wholesale (a generated file, say), not as a way to make red text go away.

## 7. The dangerous one: no conflict, but broken

Git only detects **textual** overlap. A **semantic conflict** is when two changes don't overlap in text but are incompatible in meaning.

```java
// feature/rename (renames the method, updates the callers it knows about)
List<Task> findAllByStatus(TaskStatus status);

// main (cut before the rename, adds a NEW caller in a NEW file)
public class TaskReportService {
    long doneCount() {
        return taskRepository.findByStatus(TaskStatus.DONE).size();  // old name
    }
}
```

No lines overlap, so Git merges silently. The result doesn't compile. The Spring Boot-specific variant is nastier because it fails only at **runtime**:

- **Flyway/Liquibase collisions.** Both branches add a migration. Branch A adds `V3__add_priority.sql`, branch B adds `V3__add_due_date.sql`. Different filenames, so Git reports zero conflicts. On startup, Flyway fails because there are two migrations with version 3. Git cannot see that the _filename's version number_ is a shared resource.
- **Duplicate `@Bean` definitions or conflicting `application.properties` keys** introduced in different files.
- **Spring Data derived queries.** A method name _is_ the query (`findByStatus` is parsed at startup), so a rename can break the context load even if everything compiles.

The defense is **not** inside Git: build and test after _every_ merge, even clean ones, and run the CI pipeline before pushing a merge to a shared branch. A merge that auto-completed deserves exactly as much verification as one that conflicted.

## 8. Conflict types beyond "both edited a line"

- **Modify/delete.** One side deleted the file, the other changed it. You must decide whether the deletion wins (`git rm file`) or the modified version survives (`git add file`).
- **Rename detection.** Git doesn't record renames. It _infers_ them at merge time by comparing content similarity (default threshold: about 50%). If one branch renames `TaskService.java` to `TaskManager.java` and the other edits `TaskService.java`, Git can usually apply the edit to the renamed file. But a rename combined with a heavy rewrite may look like delete + add, producing confusing conflicts. This is why refactoring commits should be **separate** from behavior-changing commits, and why renaming and rewriting in one commit is risky.
- **Directory renames and Java packages.** Moving a package (say `com.arcade.doitlater.service` → `com.arcade.doitlater.tasks`) while another branch adds a new class to the old package is a known trap. Modern Git (the default `ort` strategy) detects the directory move and, by default, flags it so you can confirm where the new file should land rather than silently relocating it. Even so, the new file's `package` declaration still says the old package, which is yet another semantic conflict the compiler will find.
- **Binary files** can't be merged line-wise. Pick a side with `--ours`/`--theirs`.
- **Whitespace and line endings.** CRLF vs LF, or reformatting, makes whole files conflict. Options: `-Xignore-space-change`, `-Xignore-cr-at-eol`, `-Xrenormalize`. A `.gitattributes` with `* text=auto` prevents recurrence.

## 9. "Ours" and "theirs" flip depending on the operation

This confuses almost everyone, and it makes sense once you ask what Git is _building_:

|Operation|"Ours" is|"Theirs" is|
|---|---|---|
|`git merge X`|Your current branch|`X`|
|`git cherry-pick C`|Your current branch|Commit `C` being applied|
|`git stash pop`|Your current working state|The stash|
|**`git rebase main`**|**`main` (what you're rebasing onto)**|**Your own commit being replayed**|

Why the flip in a rebase? Rebase starts from `main`'s tip and **replays your commits one at a time on top of it**. At each step, the thing being built is "main plus some of your commits," so that's "ours" (the base we're standing on), and your commit is the incoming change, "theirs". In a rebase, `git checkout --theirs file` therefore means _keep my feature's version_, which is the opposite of what it sounds like.

Two more rebase-specific consequences:

- A rebase resolves conflicts **once per replayed commit**. A branch with 12 commits touching the same hotspot can mean 12 rounds. Squashing first (`git rebase -i`) or enabling `rerere` (below) reduces the pain.
- Stage state lives in `.git/rebase-merge/`, and the commands are `git rebase --continue` / `--abort` / `--skip`, not `merge --continue`.

Also, a conflicted `git stash pop` **does not drop the stash**, so your work is still safe in `git stash list` while you resolve.

## 10. Strategy options: powerful and easy to misuse

```bash
git merge -X ours   feature    # on conflicting hunks only, prefer our side
git merge -X theirs feature    # on conflicting hunks only, prefer their side
git merge -s ours   feature    # a different thing entirely
```

||Brings in other side's non-conflicting changes?|Conflicting hunks|
|---|---|---|
|`-X ours`|Yes|Ours wins|
|`-X theirs`|Yes|Theirs wins|
|`-s ours`|**No**, discards everything from the other branch|N/A|

`-s ours` records "feature was merged" in history while keeping your tree **unchanged**. It's a legitimate tool for formally retiring an abandoned branch, and a disaster if used by accident. `-X theirs` silently discards your work in every conflict, so it fits mechanical cases (generated files) and not code you care about.

Other useful `-X` options: `-Xpatience` or `-Xhistogram` (different diff algorithms; they can produce smaller, saner conflicts when code has been moved around), `-Xfind-renames=<n>` (tune rename sensitivity), `-Xno-renames`.

## 11. Advanced tooling

**`rerere` (reuse recorded resolution).**

```bash
git config --global rerere.enabled true
```

Git records the conflict and _how you resolved it_, then replays that resolution automatically if the identical conflict shows up again. It shines when you rebase a long-lived branch repeatedly, or when you abort a merge and retry it. `git rerere status` shows what it has recorded.

**Investigating _why_ it conflicts.**

```bash
git log --merge -p -- path/File.java   # commits from BOTH sides that touch the conflicted file
git merge-base main feature            # what is the actual base?
git diff main...feature                # what feature changed since the base
```

**Auditing a merge after the fact.** Resolutions live _inside the merge commit_ and don't belong to either parent, so they're easy to get wrong unnoticed (these are sometimes called "evil merges"):

```bash
git show --cc <merge-commit>            # combined diff: only lines differing from all parents
git show --remerge-diff <merge-commit>  # Git 2.36+: shows exactly what YOUR resolution changed
                                        # relative to the auto-merge with markers
```

`--remerge-diff` is excellent for code review of merge commits, since it shows only the human decisions.

**Controlling merging per file type** (`.gitattributes`):

```
*.sql   merge=union      # concatenates both sides' lines, never conflicts
```

`merge=union` suits append-only files such as changelogs, but it will happily produce garbage in code or `pom.xml`, so use it narrowly.

## 12. Undoing and recovering

|Situation|Command|
|---|---|
|Mid-merge, want out|`git merge --abort`|
|Mid-rebase, want out|`git rebase --abort`|
|Resolved wrongly, not yet committed|`git checkout --merge -- file` to restore the markers|
|Merge committed, not pushed|`git reset --hard ORIG_HEAD` (discards uncommitted work, so check `git status` first)|
|Merge already pushed|`git revert -m 1 <merge-commit>`|

Note: after `git revert -m 1`, re-merging the same branch later brings in _nothing_, since Git considers it already merged. You first have to revert the revert.

## 13. Reducing conflicts in practice

- **Integrate often.** Merge `main` into your branch daily. Small, frequent conflicts beat one giant one, because the conflict size scales with how far the branches have drifted apart.
- **Keep commits focused.** Separate formatting, renames, and package moves from logic changes.
- **Agree on a formatter and import order** (and apply it on a quiet day in its own commit), so nobody's IDE reformats whole files.
- **Avoid hot-spot files** where possible: god classes, one huge `application.properties`, one giant config. Splitting them reduces collisions.
- **Add CI checks for what Git can't see**, such as the build, tests, and a Flyway validation step.

## 14. Check your understanding

**Question 1.** On `main`, a teammate changes line 40 of `OrderService.java`. On your branch you changed line 41 of the same file. You merge and Git reports a conflict. A colleague insists "that's impossible, we edited different lines." Explain exactly why Git conflicted, and what small change to the edits would have let it merge cleanly. Then say what _wouldn't_ be caught even if it merged cleanly.

**Question 2.** You're running `git rebase main` on your feature branch and hit a conflict in `application.yml`. You decide the version from **your feature commit** is the correct one for the whole file. Which of `--ours` or `--theirs` do you pass to `git checkout`, and why? Then explain what would have been different had you run `git merge main` instead, in terms of what Git is building at that moment.

---
# Answers

## Question 1: adjacent lines (40 vs 41)

**Why Git conflicted:** Git doesn't decide per line number. It decides per **hunk**, a contiguous block of changed lines. Two hunks conflict if they **overlap or touch**, meaning there is no unchanged line between them.

```
line 39   unchanged
line 40   theirs edits   ┐ adjacent hunks, no unchanged
line 41   ours edits     ┘ line between them → CONFLICT
line 42   unchanged
```

Your colleague is right that you edited _different lines_. But Git needs an **unchanged anchor line** between two edits to be confident about where one change ends and the other begins. With none, it can't tell whether the two edits are logically separable, so it refuses to guess. Lines that are changed next to each other are very often related (a signature and its body, a variable and its first use), so playing it safe is the right default.

**The small change that would have merged cleanly:** if the teammate had edited line 40 and you had edited line 42 (or 43, and so on), leaving line 41 untouched, the hunks would be separated by an unchanged line and Git would merge them silently.

**What wouldn't be caught even if it merged cleanly:** **semantic conflicts**. Git only sees text, not meaning. Examples in your context:

- Line 40 renames `findByStatus` to `findAllByStatus` in a Spring Data repository, while you add a call to `findByStatus` on a line far away. There's no textual overlap, so no conflict, but it won't compile.
- A line you didn't touch at all (say line 90) depends on an assumption that the teammate's line 40 change just invalidated.
- Two Flyway migrations with the same version number in different files merge cleanly but crash at startup.

The lesson: a textual conflict means Git is unsure, but a clean merge never means Git is sure the code is correct. Always build and test after merging.

## Question 2: `--ours` vs `--theirs` in a rebase

**Answer: `--theirs`.**

```bash
git checkout --theirs -- application.yml
git add application.yml
git rebase --continue
```

(Modern equivalent: `git restore --theirs application.yml`.)

**Why: what Git is building at that moment.** The labels describe _roles in the operation_, not who wrote what.

A rebase works like this:

1. Git checks out the tip of `main` (the branch you're rebasing **onto**), in a detached state.
2. It then **replays your feature commits one at a time on top of it**.

So when a conflict happens mid-replay:

```
main tip ── (your commit 1 replayed) ── ► now applying your commit 2  ✗ conflict
\_____________ "ours" ______________/    \_______ "theirs" _______/
  what we're standing on / building          the incoming change
```

- **Ours** is the work-in-progress result: `main` plus the feature commits already replayed.
- **Theirs** is the single commit currently being applied, **your own feature commit**.

So "my feature's version" is `--theirs`. It sounds backwards, but it follows from rebase's design: the _incoming_ thing is your own work.

**If you had run `git merge main` instead:**

```
feature (you are here) ◄── merging in ── main
        "ours"                          "theirs"
```

Here Git builds a result **on top of your current branch**, and brings the other branch in. Ours is your feature branch, theirs is `main`. To keep your feature's version of the file you'd use `--ours`, the exact opposite flag for the same intent.

A mnemonic that works for both: **ours is what you're standing on; theirs is what's being brought in.** The only thing that changes between merge and rebase is which of your two branches plays each role.

## Two caveats worth knowing

1. **`--theirs` takes the whole file** from that commit, including discarding any _non-conflicting_ changes `main` made to `application.yml` (stage 3 replaces the entire file). If `main` changed some other property that you do want, resolve by hand, or use `-X theirs` on the rebase to prefer your side **only for conflicting hunks**. For Spring configuration files, where several people add unrelated properties, hand-merging is usually safer.
2. **"Your version" means that specific commit's version**, not your final branch tip. In a multi-commit rebase, later commits get replayed afterwards and may conflict again. This is also why `rerere` and squashing first can save you repeated rounds.

Finally, you can always sanity-check which side is which with `git status`. During a rebase it shows `rebase in progress; onto <main-hash>`, which confirms that "ours" is that `onto` base.





[[Git & Github]]