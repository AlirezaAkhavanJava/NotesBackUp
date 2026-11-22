
`ls` means **list directory contents**. In Bash/Linux, its behavior is controlled mainly by **options** (often called flags), not "modules."

## Basic `ls`

```bash
ls
```

Lists files and directories in the current directory.

```bash
ls /etc
```

Lists `/etc`.

---

## Important `ls` options

### `-l` — long format

```bash
ls -l
```

Shows detailed information:

```text
-rw-r--r--  1 ethan ethan  1234 Oct  2 20:30 file.txt
```

The fields are roughly:

```text
permissions  links  owner  group  size  date  name
```

---

### `-a` — all

```bash
ls -a
```

Includes hidden files:

```text
.
..
.bashrc
.git
file.txt
```

Linux hidden files normally start with `.`.

Very common:

```bash
ls -la
```

or:

```bash
ls -al
```

The order of options usually doesn't matter.

---

### `-h` — human-readable sizes

Usually combined with `-l`:

```bash
ls -lh
```

Instead of:

```text
1048576
```

you get something like:

```text
1.0M
```

Common combination:

```bash
ls -lah
```

Meaning:

```text
-l  long format
-a  include hidden files
-h  human-readable sizes
```

---

### `-R` — recursive

```bash
ls -R
```

Lists the directory and its subdirectories recursively.

Be careful with this on large directories—it can produce a **lot** of output.

---

### `-t` — sort by modification time

```bash
ls -lt
```

Newest files first.

Reverse it:

```bash
ls -ltr
```

So:

```text
-t  time sorting
-r  reverse
```

---

### `-S` — sort by file size

```bash
ls -lS
```

Largest first.

Reverse:

```bash
ls -lSr
```

---

### `-1` — one entry per line

```bash
ls -1
```

Useful when you want machine-friendly-ish output:

```text
file1
file2
file3
directory
```

---

## Combining options

This:

```bash
ls -lah
```

is equivalent to:

```bash
ls -l -a -h
```

You can also use long-form options:

```bash
ls --all --human-readable --long
```

Short options are simply more convenient.

---

## `ls` is actually a program

You can inspect it:

```bash
type ls
```

On Debian, you may get something like:

```text
ls is aliased to `ls --color=auto'
```

That's important: your `ls` might actually be an **alias**.

Check:

```bash
alias ls
```

And find the actual executable:

```bash
command -v ls
```

Typically:

```text
/usr/bin/ls
```

You can see its available options with:

```bash
ls --help
```

or its manual:

```bash
man ls
```

### A useful mental model

```text
ls
│
├── options
│   ├── -l   detailed information
│   ├── -a   hidden files
│   ├── -h   human-readable sizes
│   ├── -R   recursive
│   ├── -t   sort by time
│   └── -S   sort by size
│
└── arguments
    ├── ls file.txt
    ├── ls /etc
    └── ls *.java
```

So when you say **"modules and tags"**, for normal Linux commands the terminology you'll want is usually **options/flags** and **arguments**.

[[2 - Tags/Pro/CS/Linux|Linux]]