Git has two layers of commands. **Porcelain** commands (`add`, `commit`, `push`…) are the friendly ones you use every day. **Plumbing** commands (`hash-object`, `write-tree`…) are the low-level tools those friendly commands are built from.

You only need porcelain to work. Plumbing is worth a quick look because it shows what Git really is: a simple database of snapshots. Once you see that, the everyday commands stop feeling like magic.

## The one picture to keep in mind

```
working folder  --add-->  staging area (index)  --commit-->  local repo  --push-->  remote
```

Almost every porcelain command moves your changes one step along this line.

## Porcelain: what you'll actually use

|Command|What it does|Example|
|---|---|---|
|`git status`|Shows what's changed, staged, or untracked|`git status -s` (short form)|
|`git add`|Moves changes into the staging area|`git add file`, `git add .`, `git add -p` (pick hunks)|
|`git commit`|Saves the staged changes as a snapshot|`git commit -m "msg"`|
|`git log`|Shows history|`git log --oneline`|
|`git branch`|Lists, creates, deletes branches|`git branch feature-x`, `git branch -d feature-x`|
|`git merge`|Brings another branch into the current one|`git merge feature-x`, `git merge --abort`|
|`git push`|Uploads your commits|`git push origin main`|
|`git pull`|Downloads and merges remote commits|`git pull --rebase origin main`|

Four details that save you from mistakes:

- **`git commit -a`** stages and commits changes to files Git already tracks. It skips brand-new files, so you still need `git add` for those.
- **`git pull` is two steps in one**: `git fetch` (download) and then a merge. With `--rebase`, the second step replays your commits on top instead of merging.
- **`git push --force`** can wipe out other people's work. Prefer `git push --force-with-lease`, which refuses if the remote changed since you last looked.
- **`git branch -d`** only deletes merged branches. Use `-D` to force it.

---
## Plumbing: build a commit by hand

Instead of a list of commands, here is the best way to learn plumbing. You create a commit without using `add` or `commit` at all.

```bash
echo "hello" > file.txt

git hash-object -w file.txt     # 1. store the file as a blob, prints its hash
git update-index --add file.txt # 2. put it in the staging area
git write-tree           # 3. turn the staging area into a tree, prints a hash
git commit-tree <tree-hash> -m "First commit" # 4. wrap the tree in a commit, prints a hash
git update-ref refs/heads/main <commit-hash> # 5. point the branch at that commit
```

Here is what each step does:

1. A **blob** is a file's contents. Git names it by its hash.
2. The **index** is the staging area.
3. A **tree** is a folder snapshot. It lists blobs and other trees.
4. A **commit** is a tree plus a message, an author, and (usually) a parent. Add `-p <parent-hash>` to link it to a previous commit.
5. A **branch** is just a tiny file holding a commit hash. `update-ref` writes it.

So `git add` and `git commit` are shortcuts for steps 1 to 5.

### Inspection tools

|Command|Use|
|---|---|
|`git cat-file -t <hash>`|Tells you the object's type (`blob`, `tree`, `commit`)|
|`git cat-file -p <hash>`|Prints the object's contents nicely|
|`git rev-parse HEAD`|Turns a name (`HEAD`, `origin/main`) into a full hash|
|`git ls-files`|Lists tracked files. Add `-m` for modified, or `--others --exclude-standard` for untracked files that aren't ignored|

One more: `git update-index --assume-unchanged <file>` tells Git to stop checking a file for changes. It's a performance trick, not a safe way to ignore files. Use `.gitignore` for that.

## Quick rules

- Everyday work: porcelain only.
- Scripts or debugging: plumbing, because its output is stable and machine-friendly.
- Plumbing writes directly to Git's database, so test it in a throwaway repo first.
- Need more on any command? Run `git help <command>`.



[[Git & Github]]