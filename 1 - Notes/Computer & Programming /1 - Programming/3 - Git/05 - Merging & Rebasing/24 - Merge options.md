
# `git merge` options

## 1. Core intuition

`git merge` makes **four separate decisions**. Almost every option controls one of them:

1. **Shape:** should history get a merge commit, or just slide a branch label forward? (`--ff`, `--no-ff`, `--ff-only`, `--squash`)
2. **Timing:** should Git commit automatically, or stop so you can inspect first? (`--commit`, `--no-commit`)
3. **Content algorithm:** how are the two sets of changes combined, and who wins in a conflict? (`-s`, `-X`)
4. **Bookkeeping:** the commit message, signing, hooks, output verbosity, and conflict flow control.

If you remember this grouping, the option list stops being a wall of flags. Each flag belongs to one of the four boxes.

## 2. Shape: what kind of history results

Starting point:

```
D---E   main
     \
      A---B   feature
```

|Option|Behavior|
|---|---|
|`--ff` (default)|Fast-forward if possible (no merge commit), otherwise create a merge commit|
|`--no-ff`|**Always** create a merge commit, even when a fast-forward was possible|
|`--ff-only`|Fast-forward or **fail**. Never creates a merge commit|
|`--squash`|Apply the changes as uncommitted edits, with **no merge commit and no second parent**|

**Why `--no-ff` exists:** a fast-forward erases the fact that a branch ever existed. The commits `A` and `B` just look like they were made directly on `main`. With `--no-ff`, a merge commit `M` wraps them, so `git log --first-parent main` shows one tidy line per feature, and reverting a whole feature is one command (`git revert -m 1 M`).

**Why `--ff-only` exists:** it's a safety rail for "I only expect to catch up, and if the branches diverged, I want to know." On failure it prints `fatal: Not possible to fast-forward, aborting.` and changes nothing.

**`--squash` is different in kind.** It leaves the changes staged and _does not record that a merge happened_:

```bash
git merge --squash feature
git commit -m "Add task priority feature"
```

Consequences: history stays linear, but Git doesn't know `feature` was merged, so `git branch -d feature` refuses (you need `-D`), and re-merging `feature` later would try to reapply the same changes. You also can't combine `--squash` with `--no-ff` or `--commit`; Git rejects it.

## 3. Timing: commit now, or let me look first

|Option|Behavior|
|---|---|
|`--commit` (default)|If the merge is clean, create the commit automatically|
|`--no-commit`|Stop just before committing, so you can run tests or tweak files|
|`-e` / `--edit`|Open the editor for the message (default when run interactively)|
|`--no-edit`|Accept the auto-generated message|

`--no-commit` has a trap: **it cannot stop a fast-forward**, because a fast-forward creates no commit to withhold. If you want a guaranteed pause, combine it:

```bash
git merge --no-ff --no-commit feature
./mvnw -q test          # verify before committing
git commit              # or: git merge --abort
```

This is the safest way to merge something risky, since a merge can succeed textually while breaking the build (see semantic conflicts).

## 4. Content: strategies (`-s`) and strategy options (`-X`)

**A strategy is the algorithm. A strategy option tunes it.** Confusing the two is the classic mistake.

### Strategies (`-s`)

|Strategy|What it does|
|---|---|
|`ort`|**Default** since Git 2.34. A three-way merge with rename detection. Handles multiple merge bases (criss-cross merges) by merging the bases first. Faster and more correct than its predecessor|
|`recursive`|The previous default. In modern Git it's essentially an alias for `ort` behavior|
|`resolve`|Simpler three-way merge, only two heads, **no rename handling**. Rarely useful|
|`octopus`|Merging **more than two** branches into one commit. It refuses to proceed if any conflict arises|
|`ours`|Creates a merge commit but **discards everything from the other branch**|
|`subtree`|A variant of `ort` for merging a project that lives in a subdirectory|

### Strategy options (`-X`) for `ort`

|Option|Meaning|
|---|---|
|`-X ours`|On **conflicting hunks only**, prefer our side|
|`-X theirs`|On conflicting hunks only, prefer their side|
|`-X patience` / `-X histogram` / `-X minimal` / `-X diff-algorithm=<alg>`|Pick a different diff algorithm; useful when code was moved around and the default produces absurd conflicts|
|`-X ignore-space-change`, `-X ignore-all-space`, `-X ignore-space-at-eol`, `-X ignore-cr-at-eol`|Ignore whitespace or line-ending differences when deciding what changed|
|`-X renormalize`|Re-normalize line endings and filters before merging (helps CRLF/LF mixes)|
|`-X find-renames[=<n>]` / `-X no-renames`|Tune or disable rename detection (default similarity is about 50%)|
|`-X subtree[=<path>]`|Shift the trees to line up, for subtree merges|

### The critical distinction

||Takes the other side's **non-conflicting** changes?|Conflicts|
|---|---|---|
|`-X ours`|Yes|Our side wins|
|`-X theirs`|Yes|Their side wins|
|`-s ours`|**No**, nothing from the other branch|N/A|

`-s ours` records "feature was merged" in the history while leaving your tree **exactly as it was**. It's legitimate for formally retiring an abandoned branch, and a disaster when typed by accident. `-X theirs` silently discards your work wherever there's a conflict, so use it for mechanical cases (generated files) and not for code you care about.

## 5. Bookkeeping: message, signing, hooks, output

**Message**

|Option|Meaning|
|---|---|
|`-m <msg>`|Set the merge commit message (can be repeated for multiple paragraphs)|
|`-F <file>`|Read the message from a file|
|`--log[=<n>]` / `--no-log`|Include one-line summaries (up to `n`) of the merged commits in the message|
|`--signoff` / `--no-signoff`|Add a `Signed-off-by:` trailer|
|`--cleanup=<mode>`|How to tidy the message: `strip`, `whitespace`, `verbatim`, `scissors`, or `default`|

**Signing and verification**

|Option|Meaning|
|---|---|
|`-S[<keyid>]` / `--gpg-sign`|GPG-sign the merge commit|
|`--no-gpg-sign`|Override a config that signs by default|
|`--verify-signatures`|Refuse to merge unless the commits being merged have valid signatures|

**Hooks:** `--no-verify` bypasses the `pre-merge-commit` and `commit-msg` hooks. If your team uses them for checks, bypassing them should be deliberate.

**Output**

|Option|Meaning|
|---|---|
|`--stat` / `-n` (`--no-stat`)|Show or hide the diffstat at the end|
|`--compact-summary`|A condensed summary showing created/deleted/mode-changed files|
|`-q` / `-v`|Quieter or more verbose|
|`--progress` / `--no-progress`|Force or suppress progress output|

## 6. Special-purpose options

**`--allow-unrelated-histories`**: Since Git 2.9, merging two branches with **no common ancestor** is refused by default. There is no merge base for the three-way merge, so Git assumes you've made a mistake. This option overrides that. Typical legitimate use: absorbing a separate repository into yours.

```bash
git remote add other ../other-repo
git fetch other
git merge other/main --allow-unrelated-histories
```

**`--autostash`**: Stashes your uncommitted changes before merging and reapplies them afterwards. Normally Git refuses to merge when uncommitted edits touch files the merge would change. `--autostash` removes that obstacle, but the pop at the end can itself conflict.

**`--rerere-autoupdate`**: If `rerere` has a recorded resolution for the conflict, it also stages the result automatically.

**`--overwrite-ignore` (default) / `--no-overwrite-ignore`**: Controls whether the merge may overwrite ignored files in your working tree.

## 7. Flow control during a conflicted merge

|Command|Effect|
|---|---|
|`git merge --abort`|Cancel the merge and restore the pre-merge state (best effort if you had uncommitted changes)|
|`git merge --continue`|After resolving and `git add`-ing, finish the merge (equivalent to `git commit` here)|
|`git merge --quit`|**Forget** the in-progress merge but leave your working tree and index as they are|

`--abort` and `--quit` are easy to confuse. `--abort` rolls everything back, while `--quit` just discards Git's memory of the merge and leaves the half-merged files for you to deal with.

## 8. What you can merge, and shorthand

```bash
git merge feature            # a branch
git merge origin/main        # a remote-tracking branch (after git fetch)
git merge v1.2.0             # a tag
git merge 8d4e0b7            # any commit hash
git merge -                  # the previously checked-out branch (shorthand for @{-1})
git merge a b c              # octopus: more than two at once
```

## 9. Making options permanent (config)

```bash
git config --global merge.ff false              # same as always passing --no-ff
git config --global merge.ff only               # same as always passing --ff-only
git config --global merge.conflictStyle zdiff3  # show the base version inside conflict markers
git config --global merge.log true              # include commit summaries in merge messages
git config --global rerere.enabled true         # remember conflict resolutions
git config --global pull.ff only                # make "git pull" refuse non-fast-forward merges
git config branch.main.mergeoptions "--no-ff"   # per-branch default
```

`merge.conflictStyle` is the highest-value one: seeing the base version in the markers lets you reason about _intent_ instead of guessing which side is right. (`zdiff3` needs Git 2.35+; use `diff3` on older versions.)

## 10. Common combinations

|Goal|Command|
|---|---|
|Normal feature merge, preserving the feature's existence|`git merge --no-ff feature`|
|Update a branch only if it's a pure catch-up|`git merge --ff-only origin/main`|
|Inspect before committing|`git merge --no-ff --no-commit feature`|
|Collapse a messy branch into one commit|`git merge --squash feature && git commit`|
|Resolve conflicts preferring ours, keep non-conflicting theirs|`git merge -X ours feature`|
|Retire a branch without taking its changes|`git merge -s ours old-branch`|
|Ignore whitespace noise|`git merge -Xignore-space-change feature`|
|Merge despite uncommitted local edits|`git merge --autostash feature`|

## 11. Gotchas

- **`-s` vs `-X`:** they look alike but do very different things. `-X ours` is a conflict-preference; `-s ours` discards the other branch entirely.
- **A clean merge isn't a correct merge.** No option detects semantic conflicts, such as two Flyway migrations with the same version number in different files. Build and test after merging.
- **`--no-commit` doesn't prevent fast-forwards.** Add `--no-ff` if you need the pause.
- **`--squash` loses merge tracking.** Don't keep working on the squashed branch and re-merge it later.
- **`-X theirs` is not "take their whole file."** It only decides conflicting hunks. For a whole file, use `git checkout --theirs -- file`.
- **Merge commits and revert:** reverting a merge needs `-m 1` to pick the mainline, and re-merging the same branch afterward brings nothing in until you revert the revert.

## 12. Where to see everything

```bash
git merge -h        # short option summary
git help merge      # full manual (also: man git-merge)
git help merge-strategies   # detailed explanation of -s and -X
```




[[Git & Github]]