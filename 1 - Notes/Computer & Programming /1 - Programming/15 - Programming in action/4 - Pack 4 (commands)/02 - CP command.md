
`cp` is the Linux/Bash command for **copying files and directories**.

### Basic syntax

```bash
cp <source> <destination>
```

### Copy a file

```bash
cp file.txt backup.txt
```

Creates:

```text
file.txt
backup.txt
```

The original remains unchanged.

### Copy into a directory

```bash
cp file.txt ~/Documents/
```

Result:

```text
~/Documents/file.txt
```

### Copy multiple files

```bash
cp file1.txt file2.txt ~/Documents/
```

### Copy a directory

You need `-r` (recursive):

```bash
cp -r project/ backup/
```

This copies the entire directory and its contents.

### Useful options

|Command|Meaning|
|---|---|
|`cp file dir/`|Copy file into directory|
|`cp -r dir/ dest/`|Copy directory recursively|
|`cp -i file dest`|Ask before overwriting|
|`cp -v file dest`|Show what is being copied|
|`cp -a dir/ dest/`|Archive copy; preserves metadata|
|`cp -u file dest`|Copy only if source is newer|

For example:

```bash
cp -av project/ backup/
```

`-a` is particularly useful for backups because it preserves things like permissions, timestamps, symbolic links, etc.

### `cp` vs `mv`

```bash
cp file.txt backup.txt
```

means:

```text
original ──────┐
               ├──> copy
               └──> original still exists
```

While:

```bash
mv file.txt backup.txt
```

means:

```text
original ──> new location/name
```

So:

**`cp` = copy**  
**`mv` = move/rename**


[[2 - Tags/Pro/CS/Linux|Linux]]