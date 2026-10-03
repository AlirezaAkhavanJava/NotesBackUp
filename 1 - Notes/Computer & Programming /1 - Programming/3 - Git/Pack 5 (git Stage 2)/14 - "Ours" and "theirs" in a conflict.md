



## 1. Core intuition

"Ours" and "theirs" are **roles**, not authorship.

Picture a **house renovation**. You're standing inside the house, which has your walls and your furniture. A contractor arrives with a truck of new parts to install.

- **Ours** is the house you're standing in: the thing receiving the changes.
- **Theirs** is the truck: the thing being brought in.

Git assigns the roles by what the **operation is building**, not by who wrote the code. In a normal merge you're standing in your own branch, so "ours" happens to be your work. In a rebase, Git builds the result on top of the _other_ branch, so the roles flip. That flip causes nearly all the confusion.

One-sentence rule: **ours is the base the result is being built on; theirs is the change being applied onto it.**

## 2. Where ours and theirs show up

### In the conflict markers

```java
<<<<<<< HEAD
    private static final int MAX_RETRIES = 3;    // ours
=======
    private static final int MAX_RETRIES = 5;    // theirs
>>>>>>> feature/retry-policy
```

The top block is ours, labeled `HEAD` (the commit currently checked out). The bottom block is theirs, labeled with what's being brought in.

The label after `>>>>>>>` tells you which operation you're in:

|Operation|Label on the "theirs" side|
|---|---|
|`merge`|Branch name, e.g. `feature/retry-policy`|
|`rebase`, `cherry-pick`|`4fa2c1e (Add retry policy)`: the commit being replayed|
|`stash pop`|`Stashed changes` (and the top is `Updated upstream`)|

### In the index (the stages)

|Stage|Contents|
|---|---|
|1|Base (common ancestor)|
|2|**Ours**|
|3|**Theirs**|

```bash
git show :2:path/File.java    # our version
git show :3:path/File.java    # their version
git diff --ours               # working file vs our side
git diff --theirs             # working file vs their side
git diff --base               # working file vs the common ancestor
```

So "ours" literally means _stage 2_ and "theirs" means _stage 3_. Whichever operation you're in, Git fills those slots according to the rules below.

## 3. The role table

|Operation|Ours (stage 2)|Theirs (stage 3)|
|---|---|---|
|`git merge X`|Your current branch|`X`|
|`git cherry-pick C`|Your current branch|The commit `C` being applied|
|`git revert C`|Your current branch|The **inverse** of commit `C` (the undo patch)|
|`git stash pop` / `apply`|The working state you're on|The stash|
|**`git rebase main`**|**`main` plus the commits already replayed**|**Your own commit currently being replayed**|
|`git pull`|Same as merge|Same as merge|
|`git pull --rebase`|Same as rebase (flipped)|Same as rebase (flipped)|

Notice that everything except rebase follows the "standing on my branch, bringing something in" pattern. Rebase is the odd one out, and `pull --rebase` inherits that behavior, which is a common source of confusion.

## 4. Why rebase flips

A merge says: "keep my branch, bring theirs in." Rebase works differently:

1. Git takes the tip of `main` (the branch you're rebasing **onto**).
2. It **replays your commits one at a time** on top of it.

```
main:     A---B---C                        ← the base we're building on = "ours"
                   \
                    your1' ---> your2 ✗    ← the commit being applied now = "theirs"
```

While a conflict is happening, the thing under construction is "`main` + the earlier replayed commits," so that's "ours." The incoming change is _your own_ commit, so that's "theirs." From Git's point of view it's applying someone's patch to a branch, and the patch happens to be yours.

Practical translation for "I want to keep my feature version":

|Situation|Flag|
|---|---|
|During `git merge main` (you're on `feature`)|`--ours`|
|During `git rebase main` (you're on `feature`)|`--theirs`|

## 5. Worked example: same conflict, two operations

Base file on `main` and `feature`'s common ancestor:

```java
private static final int MAX_RETRIES = 2;
```

`main` changed it to `3`. `feature` changed it to `5`.

**Merge, while on `feature`: `git merge main`**

```java
<<<<<<< HEAD
    private static final int MAX_RETRIES = 5;     // feature (you)
=======
    private static final int MAX_RETRIES = 3;     // main
>>>>>>> main
```

**Rebase, while on `feature`: `git rebase main`**

```java
<<<<<<< HEAD
    private static final int MAX_RETRIES = 3;     // main  (ours now!)
=======
    private static final int MAX_RETRIES = 5;     // your feature commit (theirs now!)
>>>>>>> 4fa2c1e (Raise retry limit)
```

Same underlying situation, but the two sides are **swapped in the file**. In the rebase, the `HEAD` section is `main`'s version. Resolve it the same way in your head ("which value do I want?") and ignore the labels' apparent meaning.

## 6. The commands that use ours/theirs

### Whole-file: pick one side's entire version

```bash
git checkout --ours   -- path/File.java
git checkout --theirs -- path/File.java
# modern equivalents:
git restore --ours   path/File.java
git restore --theirs path/File.java
git add path/File.java
```

This replaces the **whole file**, including parts that merged cleanly from the other side. If `main` changed three unrelated things in `application.yml` and you take `--ours` (your side), you also lose those three changes. It's the right tool for binaries and generated files, and often the wrong tool for code.

### Per-hunk: strategy options

```bash
git merge  -X ours   feature     # conflicting hunks: prefer ours; everything else merges normally
git merge  -X theirs feature
git rebase -X theirs main        # in a rebase, this prefers YOUR commit's side (the flip applies here too)
```

`-X` only decides **conflicting hunks**. Non-conflicting changes from both sides are combined as usual.

### Whole-merge: strategy

```bash
git merge -s ours old-branch
```

This is a different thing entirely: it records a merge but **takes nothing** from the other branch. The `-s ours` name is unrelated to the "ours" stage, other than sharing a word.

||Other side's non-conflicting changes|Conflicting hunks|
|---|---|---|
|`checkout --ours file`|Lost (whole file replaced)|Ours|
|`-X ours`|Kept|Ours|
|`-s ours`|**All lost**|N/A|

### Redo a botched resolution

```bash
git checkout --merge -- path/File.java        # recreate the conflict markers
git checkout --conflict=diff3 -- path/File.java   # recreate them with the base shown
```

`--ours`/`--theirs` only work on paths that are **still unmerged**. After you `git add` a file, those flags no longer apply, so use `--merge` to bring the conflict back first.

## 7. Nuances and gotchas

- **Rebase flips; `pull --rebase` flips too.** If you configured `pull.rebase true`, every `git pull` conflict uses rebase semantics, which surprises people who think they're "just pulling."
- **Multi-commit rebases:** "theirs" changes at each step, since it's the commit currently being replayed. "Ours" accumulates, because each replayed commit becomes part of the base for the next one. A single conflict resolution applies to one step only; this is why `rerere` helps.
- **Revert is double-inverted.** In `git revert C`, "theirs" is the _undo_ of `C`, so taking `--theirs` means "go ahead with the revert here," and `--ours` means "keep the code as it currently is."
- **Modify/delete conflicts.** `deleted by us` means _our_ side removed it while they changed it. Here `--ours` gives you the deletion and `--theirs` gives you their modified file. Often there are no markers at all; you decide with `git rm file` (accept the deletion) or `git add file` (keep it).
- **Add/add conflicts.** Both sides created the same path. There's no meaningful base (stage 1 is missing), so the markers just show two unrelated versions.
- **Rename conflicts** can put the file at an unexpected path with flags like `added by us`. Check `git status` and `git ls-files -u` for the stages that exist.
- **Binary files** can't have markers, so `--ours`/`--theirs` is the standard way to decide.
- **A custom merge driver** in `.gitattributes` (`merge=ours`) makes Git always keep our version of matching files during merges (for example, a local environment file). It needs the driver configured: `git config merge.ours.driver true`.
- **`git log --merge`** shows commits from _both_ sides that touched the conflicted files, which is a quick way to learn what theirs actually changed.
- **GUI labels differ.** IntelliJ's three-pane merge tool labels its panes with its own wording (for example "Local changes" vs. incoming changes), and which side is which can depend on whether you merged or rebased. Check the header of each pane and don't assume left means ours.

## 8. Mental checklist when you're unsure

1. Which operation am I in? (`git status` says `rebase in progress`, `You have unmerged paths` after a merge, and so on.)
2. Ask: _what is Git building on top of?_ That's ours. The change being applied is theirs.
3. Look at the label after `>>>>>>>`: a branch name means merge, `hash (subject)` means a commit being replayed.
4. When in doubt, look at the content, not the label. `git show :2:file` and `git show :3:file` show you both versions, so you can decide by what the code says.

## 9. Quick reference

|You want|Merge|Rebase|
|---|---|---|
|Keep the branch I was working on|`--ours`|`--theirs`|
|Keep the branch I'm bringing in / onto|`--theirs`|`--ours`|
|Prefer my side on conflicting hunks only|`-X ours`|`-X theirs`|
|Keep my side, but only if conflicting, in whole-file form|`checkout --ours`|`checkout --theirs`|

(Here "the branch I was working on" means your feature branch.)





[[Git & Github]]