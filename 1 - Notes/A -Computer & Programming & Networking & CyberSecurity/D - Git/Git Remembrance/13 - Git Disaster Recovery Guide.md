

> **Read this before you panic.** Every "disaster" below is fixable. Git almost never truly loses committed data for ~90 days (reflog). The real danger is *running more commands while panicking*. Rule #1: **STOP. Read. Then act.**

---

## How to use this file

Each section follows the same format:

1. ** The Fuck-Up** — what you did
2. ** What's happening** — why it's scary
3. ** STOP doing this** — commands to avoid right now
4. ** The Fix** — exact commands, in order
5. ** Why it works** — so you learn

---

## 0. Universal First-Aid (read this once, remember forever)

Before ANY fix, do these two things:

```bash
# 1. Backup your current state — even if broken
cd ..
cp -r my-repo my-repo-BACKUP-$(date +%s)

# 2. See everything Git remembers
git reflog
```

`git reflog` is a log of **every place HEAD has been**, including commits you "deleted", rebased away, or reset past. It lives for ~90 days by default. If a commit ever existed on your machine, reflog has its SHA.

```bash
git reflog
# abc1234 HEAD@{0}: rebase (finish): returning to refs/heads/feature
# def5678 HEAD@{1}: rebase (pick): add login form
# 789abcd HEAD@{2}: rebase (start): checkout main
# ...
```

You can recover any of those with:
```bash
git reset --hard HEAD@{2}
```

**Golden rule:** If you're lost, `git reflog` + a filesystem backup buys you infinite retries.

---

## 1. You force-pushed your feature branch, then realized main had moved and you rebased wrong — history is a mess

###  The Fuck-Up

```bash
git switch feature
git rebase main          # conflict chaos, you resolved badly
git push --force         # overwrote remote feature branch
# ...now your branch is garbage and the remote is garbage too
```

###  What's happening

The remote `origin/feature` used to have good commits. You force-pushed over them. Your local `feature` also points at the bad rebase. It feels like two copies of your work are gone.

They're not. Both are in reflog.

###  STOP

- Don't `git push --force` again
- Don't `git rebase --abort` (rebase already finished)
- Don't delete the branch

###  The Fix

**Step 1 — Find the commit before the bad rebase.**

```bash
git reflog
```

Look for the line **just before** `rebase (start)`. Something like:

```
a1b2c3d HEAD@{5}: commit: working login form      ← GOOD
e4f5g6h HEAD@{4}: rebase (start): checkout main   ← rebase began here
...
```

The good SHA is `a1b2c3d`.

**Step 2 — Point your local branch back at it.**

```bash
git reset --hard a1b2c3d
```

**Step 3 — Force-push the restored state to remote (with lease).**

```bash
git push --force-with-lease origin feature
```

`--force-with-lease` refuses to overwrite if someone else pushed since your last fetch. Always prefer it over `--force`.

**Step 4 — Verify.**

```bash
git log --oneline -5
git status
```

###  Why it works

- `reflog` keeps every prior HEAD position, so the "lost" commit still exists as a dangling object.
- `reset --hard <sha>` re-points your branch to it.
- `--force-with-lease` is a safety belt on the remote.

---

## 2.  You rebased a branch that was already pushed and shared with a teammate — now their history diverges from yours

###  The Fuck-Up

```bash
git switch feature
git rebase main           # rewrites SHAs
git push --force          # teammate already has the old SHAs
```

Teammate now pulls and gets a nightmare of duplicate commits or conflicts.

###  What's happening

Rebase **creates new commits with new SHAs** and discards the old ones. Anyone who based work on the old SHAs now has a fork in history. Their `git pull` tries to merge two unrelated histories.

###  STOP

- Don't tell your teammate to `git pull` normally — it will make it worse
- Don't rebase again
- Don't push again

###  The Fix

**If nobody has committed on top of the old branch yet** (cleanest):

**On the teammate's machine:**
```bash
git fetch origin
git switch feature
git reset --hard origin/feature
```

They lose any local unpushed commits on `feature` — so **first** have them stash or copy them:

```bash
git switch feature
git branch feature-local-backup    # save their work
git fetch origin
git reset --hard origin/feature
git cherry-pick <sha-they-want-to-keep>
```

**If the branch has already been merged or many people track it:**

Don't rebase. Instead, revert the rebase:

**On your machine:**
```bash
git reflog                          # find SHA before the rebase
git reset --hard <sha-before-rebase>
git push --force-with-lease origin feature
```

Then everyone resets to match.

###  Why it works

Rebase is a *rewrite* operation. The fix is to either (a) make everyone converge on the rewritten version via `reset --hard origin/...`, or (b) un-rewrite via reflog.

**Lesson:** Never rebase a branch that has collaborators unless you've agreed first.

---

## 3.  You rebased main (or a shared branch) — everyone's branches are now broken

###  The Fuck-Up

```bash
git switch main
git rebase something
git push --force origin main
```

Now every teammate's branch is based on SHAs that no longer exist on `origin/main`.

###  What's happening

You rewrote shared history. This is the single worst thing you can do in Git. Every PR is now against a ghost.

###  STOP

- Don't push again
- Don't rebase further
- **Announce it in team chat immediately** — speed matters here

###  The Fix

**Fastest fix — restore main exactly as it was before your rebase.**

On your machine:
```bash
git reflog
# find: <sha> HEAD@{n}: rebase (start): checkout main
# the line ABOVE that is the good main
git reset --hard <good-main-sha>
git push --force-with-lease origin main
```

Now `origin/main` matches what it did before. Everyone's branches work again. Nobody needs to do anything.

**If force-push is disabled on main (GitHub branch protection):**
You'll need to temporarily lift protection, or revert instead:

```bash
# Safer alternative — do NOT rewrite, just add a revert
git revert <bad-commit-sha>       # creates a new commit undoing the rebase
git push origin main
```

Revert doesn't fix the SHA divergence for teammates, but it stops the bleeding.

###  Why it works

- If you can force-push main back, you've undone the rewrite and everyone continues as if nothing happened.
- If you can't force-push, revert at least makes main's *content* correct; SHAs still diverge and every teammate will need to re-sync (`git fetch && git reset --hard origin/main` on their own branches).

**Prevention:** Enable branch protection on `main`. Never `git push --force` to main. Ever.

---

## 4.  You committed on main instead of a feature branch, then pushed

###  The Fuck-Up

```bash
git switch main
# ...edit files...
git commit -m "wip"
git push origin main
```

You didn't mean to. Now main has half-done work.

###  What's happening

You can't "unpush" cleanly because main is shared. Rewriting it hurts others.

###  STOP

- Don't `git push --force origin main` to remove it (breaks others)
- Don't `git reset --hard` and force-push

###  The Fix

**Option A — No one has pulled yet, and you're allowed to force-push (small team):**

```bash
git reset --hard HEAD~1
git push --force-with-lease origin main
```

**Option B — Proper fix, always safe:**

```bash
# 1. Create a branch to carry the work
git switch -c feat/whatever-it-was

# 2. Push that branch up
git push -u origin feat/whatever-it-was

# 3. Go back to main and remove the bad commit
git switch main
git revert <bad-commit-sha>       # adds a new commit undoing it
git push origin main
```

Now main is correct (the bad commit is undone by a revert commit), and your work lives on the feature branch.

**Option C — Move the commit to a branch properly:**

```bash
git switch main
git branch feat/my-work           # point a new branch at current main
git reset --hard origin/main      # main goes back
git push origin main              # no force needed, main is back
git switch feat/my-work
git push -u origin feat/my-work
```

###  Why it works

- Revert is "safe undo" — it doesn't rewrite history, so nobody's clone breaks.
- Moving the commit to a branch preserves the work.

**Lesson:** Never commit on main. `git switch -c` **before** you touch code.

---

## 5.  You `git reset --hard` and lost uncommitted work

###  The Fuck-Up

```bash
git reset --hard HEAD
# or
git reset --hard origin/main
```

Uncommitted edits are gone. You didn't commit first.

###  What's happening

`--hard` throws away working-directory changes. These were never in a commit, so `reflog` won't help directly.

###  STOP

- Don't close the terminal (IDE undo history may still help)
- Don't run more git commands that touch the working tree

###  The Fix

**Case A — You once `git add`-ed the files (staged them):**

```bash
git fsck --lost-found
# Look in .git/lost-found/other/ for blobs
# Each file is content without a name — grep through them
```

Or the easier way:

```bash
git fsck --unreachable | grep commit
git show <blob-sha>              # inspect any blob
```

**Case B — Never staged:**

- **VS Code:** Ctrl/Cmd+Shift+P → "Local History" → recover from timeline
- **JetBrains IDEs:** Right-click file → Local History → Show History
- **macOS:** Time Machine
- **Nothing else?** The work is gone. Recreate it.

**Case C — You had stashed:**

```bash
git stash list
git stash pop
```

###  Why it works

Git stores objects when you `add` them. Even after `reset --hard`, those blobs may still be in `.git/objects` until garbage collection. `git fsck` finds them.

**Lesson:** `git add` early (it's a save point), commit often.

---

## 6.  You deleted a branch with unmerged work

###  The Fuck-Up

```bash
git branch -D feature-important
# or
git push origin --delete feature-important
```

###  What's happening

`-D` deletes even unmerged branches. But the commits are still objects in the repo.

###  STOP

- Don't run `git gc` (garbage collection deletes unreachable objects after a while)

### The Fix

**Local deletion:**
```bash
git reflog
# find: <sha> HEAD@{n}: commit: last commit on feature-important
git branch feature-important <sha>
```

Or:
```bash
git fsck --lost-found | grep commit
git show <sha>                    # verify it's the right one
git branch feature-important <sha>
```

**Remote deletion:**
- **GitHub:** deleted branches are recoverable from the GitHub UI for a while (Settings → Branches → Deleted branches, or the branch dropdown). Also check the PR — GitHub keeps the ref for ~90 days.
- If someone pushed recently, `git fetch origin refs/pull/<PR#>/head:recovered` works for PR branches.

###  Why it works

Deleting a branch just removes a label. Commits stay as long as something references them or until `gc` runs.

---

## 7.  You merged main into your branch, then realized you should have rebased — now there's an ugly merge commit and the PR shows 40 files changed

###  The Fuck-Up

```bash
git switch feature
git merge main             # creates merge commit
git push
# PR now shows all of main's history as "changes"
```

###  What's happening

The merge brought in main's commits and a merge node. The PR diff is noisy.

###  STOP

- Don't add more merges
- Don't rebase on top of this mess blindly

###  The Fix

**Step 1 — Undo the merge locally:**
```bash
git reset --hard HEAD~1          # if merge was the last commit
# OR if it's older:
git reflog
git reset --hard <sha-before-merge>
```

**Step 2 — Rebase instead:**
```bash
git fetch origin
git rebase origin/main
# resolve conflicts, then:
git push --force-with-lease
```

**Step 3 — If the branch is shared, don't force-push.** Instead, merge is correct — leave it alone. Clean history isn't worth breaking teammates.

###  Why it works

`reset --hard` removes the merge commit. Rebase replays your commits on top of main without a merge node.

---

## 8.  Interactive rebase gone wrong — you dropped a commit you needed

###  The Fuck-Up

```bash
git rebase -i HEAD~5
# accidentally marked a commit as "drop"
git push --force
```

###  What's happening

The commit exists in reflog but not in history.

###  The Fix

```bash
git reflog
# find the SHA of the dropped commit
git cherry-pick <sha>
# resolve any conflicts
git push --force-with-lease
```

If multiple commits were dropped:
```bash
git reflog
git reset --hard <sha-before-the-bad-rebase>
git rebase -i origin/main        # redo it carefully this time
git push --force-with-lease
```

---

## 9. You pulled with a merge into a branch you meant to keep linear, creating a "merge of a pull" that pollutes history

###  The Fuck-Up

```bash
git pull origin main             # implicit merge
```

Now your feature branch has a merge commit that isn't a real feature merge.

###  The Fix

```bash
git reset --hard HEAD~1          # undo the merge
git fetch origin
git rebase origin/main
git push --force-with-lease
```

**Prevention:** Always `git pull --rebase` on feature branches:
```bash
git config --global pull.rebase true
git config --global rebase.autoStash true
```

---

## 10.  You pushed a secret / password / API key

###  The Fuck-Up

You committed `.env`, a private key, or a token, and pushed.

###  What's happening

The secret is in history forever until you rewrite it — **and even then**, GitHub may have cached it, forks may have it, CI logs may have it.

###  STOP

- Don't just delete the file and commit — the old commit still has it
- Don't push more

###  The Fix

**Step 1 — REVOKE THE SECRET IMMEDIATELY.** Rotate the password/key. Assume it's compromised the moment it hit a remote. This is non-negotiable and must happen first.

**Step 2 — Remove from history (use `git-filter-repo`, not `filter-branch`):**

```bash
pip install git-filter-repo

# Backup first!
cp -r my-repo my-repo-BACKUP

# Remove the file entirely from all history
git filter-repo --path path/to/secret.env --invert-paths

# Force-push all branches
git push --force --all
git push --force --tags
```

**Step 3 — Tell collaborators to re-clone.** Their local copies still have the secret in history. They must delete and re-clone, not pull.

**Step 4 — Ask GitHub Support to purge cached views** if it was in a public repo.

###  Why it works

`git-filter-repo` rewrites every commit that touched the file, so it's gone from the new history. Revoking first means even the leaked copy is worthless.

---

## 11.  Detached HEAD with commits you didn't save

###  The Fuck-Up

```bash
git checkout <sha>
# ...commit some things...
git switch main
# your commits are "gone"
```

###  What's happening

You committed on a detached HEAD. The commits exist but no branch points at them.

###  The Fix

```bash
git reflog
# find the SHA of your detached commit
git switch -c rescue-branch <sha>
# or
git branch rescue-branch <sha>
git switch rescue-branch
```

**Prevention:** If you find yourself in detached HEAD, immediately `git switch -c new-branch-name` before committing.

---

## 12.  You accidentally committed a huge file (100MB+) and can't push

###  The Fuck-Up

```bash
git add .
git commit -m "add video"
git push
# remote: error: File is 250 MB; exceeds GitHub's 100 MB limit
```

###  What's happening

GitHub refuses the push. The file is in your commit.

###  The Fix

**If it's the last commit and not pushed:**
```bash
git rm --cached bigfile.mp4
echo "bigfile.mp4" >> .gitignore
git commit --amend --no-edit
git push
```

**If it's deeper in history:**
```bash
pip install git-filter-repo
git filter-repo --path bigfile.mp4 --invert-paths
git push --force-with-lease
```

**For future large files, use Git LFS:**
```bash
git lfs install
git lfs track "*.psd" "*.mp4"
git add .gitattributes
```

---

## 13.  "Your branch and 'origin/main' have diverged" — you have N and M different commits

###  The Fuck-Up

You pulled with rebase at some point, or you amended pushed commits. Now `git status` says history has diverged.

###  What's happening

Your local main and origin/main share a common ancestor but each has its own commits.

###  The Fix

**Inspect first:**
```bash
git log --oneline --graph --all -20
git log origin/main..HEAD        # commits you have that origin doesn't
git log HEAD..origin/main        # commits origin has that you don't
```

**If your local extra commits are junk:**
```bash
git reset --hard origin/main
```

**If your local extra commits are real work:**
```bash
git pull --rebase origin main
# resolve conflicts as they come
git push
```

**If you already pushed your extra commits as someone else's work:**
Stop. Message the other person. Decide which version is canonical. Then one of you force-pushes; the other re-syncs.

---

## Part 14: The Panic Checklist (tape this to your monitor)

When something goes wrong:

```
1. STOP. Don't run more git commands.
2. cp -r repo repo-BACKUP
3. git reflog                 ← the answer is almost always here
4. git status                 ← know where you are
5. git log --oneline --all --graph -20   ← see the shape
6. Identify the last known-good SHA.
7. git reset --hard <sha>     ← go back
8. Fix properly.
9. Push with --force-with-lease if remote is wrong.
10. Announce to team if shared branch was touched.
```

---

## Part 15: Rules That Prevent 95% of These

1. **Never commit to main.** `git switch -c` first, always.
2. **Never `git push --force`.** Use `--force-with-lease`.
3. **Never force-push to main/develop/release.** Enable branch protection on GitHub.
4. **Never rebase a shared branch.** Only your own, only before others base work on it.
5. **`git pull --rebase`** globally:
   ```bash
   git config --global pull.rebase true
   git config --global rebase.autoStash true
   git config --global push.default current
   git config --global push.autoSetupRemote true
   ```
6. **Commit often, commit small.** A commit is a save point.
7. **`git add` is also a save point.** Stage early.
8. **Read commit messages before rebasing.** `git log --oneline -20`.
9. **Run `git status` before every operation.** Always.
10. **When in doubt, `git reflog` and back up the folder.**

---

## Part 16: Config to set right now

```bash
# Safer defaults
git config --global pull.rebase true
git config --global rebase.autoStash true
git config --global push.default current
git config --global push.autoSetupRemote true
git config --global fetch.prune true
git config --global merge.conflictstyle zdiff3
git config --global rerere.enabled true       # remembers conflict resolutions
git config --global alias.lg "log --oneline --graph --all --decorate"
git config --global alias.undo "reset --soft HEAD~1"
git config --global alias.recent "reflog --date=relative"
```

Then you can do:
```bash
git lg           # pretty history
git recent       # see reflog quickly
git undo         # uncommit but keep changes
```

---

## Part 17: The Mindset

- **Git almost never loses committed work.** Reflog + `fsck` recover the rest. The only thing you can truly lose is uncommitted, unstaged work — so **commit early, commit often**.
- **The dangerous commands are the ones that rewrite or delete.** `reset --hard`, `push --force`, `rebase`, `branch -D`, `filter-repo`. Pause before each one.
- **On shared branches, the safe tools are `revert` and normal `merge`.** Never rewrite shared history.
- **Announce first, fix second** on shared branches. Teammates can't recover if they don't know.
- **The best fix is prevention:** branch per task, pull with rebase, push with lease, protect main.

You will still screw up. Everyone does. What matters is that you now know the reflog exists, you know `--force-with-lease`, and you know to *stop* instead of typing more commands in a panic. That's already better than most professional developers.

[[0 - Git 🍋‍🟩]]