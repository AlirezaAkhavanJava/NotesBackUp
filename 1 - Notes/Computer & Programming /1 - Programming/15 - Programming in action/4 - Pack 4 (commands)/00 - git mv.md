

`git mv` is Git's command for **moving or renaming a file/directory while automatically staging that change**.

### Basic syntax

```bash
git mv <source> <destination>
```

### Rename a file

```bash
git mv old-name.java new-name.java
```

Equivalent to:

```bash
mv old-name.java new-name.java
git add old-name.java new-name.java
```

Git sees it as a rename:

```text
renamed: old-name.java -> new-name.java
```

### Move a file

```bash
git mv App.java src/main/java/App.java
```

This moves the file **and stages the move**.

### Rename a directory

```bash
git mv old-folder new-folder
```

Git doesn't actually track directories—only files—so Git detects the resulting file changes as renames/moves.

### Important detail

`git mv` is basically a convenience command. Git doesn't have a special "rename object" in the repository.

For example:

```bash
git mv User.java Account.java
```

roughly performs:

```bash
mv User.java Account.java
git add User.java Account.java
```

Git later **detects** that the deletion + addition represents a rename.

You can verify the staged change with:

```bash
git status
```

or:

```bash
git diff --cached --summary
```

### If you already used `mv`

That's completely fine:

```bash
mv old.java new.java
git add -A
```

Git can still detect the rename. `git mv` is mainly a convenient way to perform the filesystem operation **and stage it in one command**.



[[Computer & Programming]]
[[Git & Github]]