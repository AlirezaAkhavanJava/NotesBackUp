


## What an orphan branch is

An orphan branch is a branch that starts with **no commit history**. It shares the same `.git` directory and object database as the rest of your repository, but its first commit has no parent.

In a normal repository, every branch traces back to a root commit — the very first commit ever made. All branches share that root. An orphan branch breaks that chain: it begins its own separate history, disconnected from everything else.

```
Normal branch:        A --- B --- C --- D  (main)
                                \
                                 E --- F   (feature, shares ancestor C)

Orphan branch:        A --- B --- C --- D  (main)

                      X --- Y --- Z        (gh-pages, no shared ancestor)
```

The two histories live in the same repo, but they never merge in the usual sense. If you ever tried to merge them, Git would refuse with "refusing to merge unrelated histories" unless you force it with `--allow-unrelated-histories`.

## Why they exist

Orphan branches are used when you want to store a completely different set of files in the same repository without polluting the main project's history. Common real-world uses:

- **GitHub Pages (`gh-pages` branch).** The compiled site output lives on an orphan branch so your built HTML/CSS does not sit next to source code.
- **Documentation branches.** A `docs` branch containing only generated documentation, no source.
- **Project templates or scaffolds.** A `template` branch that holds a bare project skeleton, unrelated to the codebase.
- **Splitting a repo.** Preparing a subset of files to become their own repository, by starting fresh history.

The key point: same repository, separate universe.

## How to create one

The modern command is `git switch --orphan`, added in Git 2.23 alongside the rest of the `switch`/`restore` split. Older Git uses `git checkout --orphan`. Both work; prefer `switch` on any current install.

### Basic creation

```bash
git switch --orphan <branch-name>
```

Example:

```bash
git switch --orphan gh-pages
```

After running this, you are on a new branch called `gh-pages`, but **you have not made any commit yet**. There is no parent commit — you are in a state where the branch does not exist as a ref until you commit.

### What happens to the working directory

This trips people up. There are two behaviors depending on your Git version and flags:

- `git switch --orphan <name>` (Git >= 2.23) — starts with a **clean working directory**. Nothing is staged. Your previous branch's files are gone from the index and from disk (as tracked files). You are literally starting from an empty directory.
- `git checkout --orphan <name>` (older) — keeps all tracked files from the previous branch **staged** in the index. You would then need to `git rm -rf .` or `git rm -r --cached .` if you want a clean start.

The `switch` version is cleaner. If you are on an older Git and see all your files staged after the orphan checkout, run:

```bash
git rm -rf .
```

to clear them before adding your new content.

### Complete example — a GitHub Pages branch

```bash
# Assume you are on main with a normal project.
git switch --orphan gh-pages

# Working directory is now empty (switch version).
# Add the compiled site files.
cp -r build/* .
git add .
git commit -m "Initial gh-pages commit"

git push -u origin gh-pages
```

The `gh-pages` branch now exists on the remote with its own root commit and no relation to `main`.

### Creating an orphan branch from scratch in an empty repo

If you already have an empty repository (no commits yet), any first branch you create is technically an orphan branch. You do not need the flag:

```bash
git init
git switch -c initial
# ... add files, commit ...
```

That `initial` branch is the root of the repo. It is not usually called an orphan branch because there is nothing else for it to be orphaned from. The term applies when a branch exists alongside existing history.

## Working with orphan branches

### Listing them

Orphan branches are just branches. They show up normally:

```bash
git branch -a
```

The only thing that identifies them as "orphan" is that `git log` on them will not share any commits with your main branch. There is no metadata flag. You can check for shared ancestry:

```bash
git merge-base main gh-pages
```

If this returns nothing (exit code 1), the branches share no ancestor — the `gh-pages` branch is orphan-rooted relative to `main`.

### Switching to and from

Normal branch switching. Nothing special.

```bash
git switch main
git switch gh-pages
```

### Pushing an orphan branch

Same as any branch:

```bash
git push -u origin gh-pages
```

The remote will accept it as a new branch with its own root.

### Pulling or fetching an orphan branch

Same as any branch. Git does not care that it lacks a common ancestor with main; it only cares that you and the remote agree on the branch's own history.

### Deleting one

Same as any branch:

```bash
git branch -D gh-pages             # local
git push origin --delete gh-pages  # remote
```

Note: `-d` (safe delete) will refuse because the branch is not "merged" into your current branch. There is no merge possible anyway, so `-D` is the correct tool.

## Things that go wrong

**You try to merge main into an orphan branch.**
Git refuses by default:

```
fatal: refusing to merge unrelated histories
```

You can force it with `git merge --allow-unrelated-histories main`, but this is almost never what you want. It creates a merge commit joining two unrelated trees, and the result is a mess. If you find yourself needing this, reconsider whether the two branches should share a repository at all.

**You forget that the orphan branch shares the object database.**
Even though the histories are separate, the objects are not. If you ever `git gc` or push, all commits from all branches are in the same pack. Secrets removed from main via `filter-repo` are still in the object database if any orphan branch references them. Orphan branches do not isolate data; they only isolate history pointers.

**You use `git checkout --orphan` on modern Git and get surprised by the staged files.**
As mentioned, older syntax leaves files staged. If you expected an empty directory, either upgrade to `git switch --orphan` or run `git rm -rf .` right after.

**You accidentally commit to the wrong branch.**
Same risk as any branch. Use `git status` before committing. On an orphan branch, `git log` will show only that branch's commits, which is a good way to confirm you are where you meant to be.

**You push and GitHub Pages does not serve the site.**
Confirm the branch name matches what GitHub Pages expects (`gh-pages` by default, or whatever you configured). Also confirm the branch contains an `index.html` at its root. GitHub Pages does not care that the branch is orphaned; it just serves files.

## Practical notes

- An orphan branch is not a special object type. It is a normal branch whose first commit happens to have no parent.
- The only way to create one is with `git switch --orphan` / `git checkout --orphan`, or by committing into a freshly initialized repository that has no prior commits.
- You can have as many orphan branches in one repository as you want. They are independent.
- You cannot convert a normal branch into an orphan branch or vice versa without rewriting history. If you want a branch's existing history gone, you would create a new orphan branch, add the content you want, and delete the old one.

## Summary

An orphan branch is a branch with no shared history with the rest of the repo. Create one with:

```bash
git switch --orphan <name>
```

Use it for content that should live in the repository but not in the main history — most commonly generated site output, standalone documentation, or project templates. Treat it as a fully separate line of development, and remember that though the history is disconnected, the repository and its object database are still shared.


[[0 - Git 🍋‍🟩]]
[[10 - Branch]]
[[22 - Git Branches 🍧]]