

**Definition:** The **working tree** is the actual set of files and directories currently checked out on your filesystem — the files you are directly editing.

In your repo:

```text
/mnt/hdd/Home/Programming Files/Git/megacorp/
```

everything you currently see there is part of the working tree.

### Git has 3 important states

```text
                 git add
Working Tree ──────────────→ Staging Area
     │                            │
     │                            │ git commit
     │                            ▼
     └──────────────────────→ Repository
                              (commits)
```

### 1. Working Tree

Your actual files:

```text
megacorp/
├── customers/
├── scripts/
│   └── scan.sh
└── README.md
```

If you edit:

```bash
vim scripts/scan.sh
```

you changed the **working tree**.

Git sees:

```bash
git status
```

something like:

```text
modified: scripts/scan.sh
```

But the commit hasn't changed.

---

### 2. Staging Area

When you run:

```bash
git add scripts/scan.sh
```

the version you staged is placed in the **index/staging area**.

Now:

```text
Working Tree
     │
     │ git add
     ▼
Staging Area
```

You can still modify the file afterward:

```bash
vim scripts/scan.sh
```

Then you can actually have:

```text
Working Tree:  version C
Staging Area:  version B
HEAD:          version A
```

This is why `git diff` and `git diff --staged` show different things.

---

### 3. Repository / HEAD

When you run:

```bash
git commit
```

the staged snapshot becomes a new commit:

```text
Working Tree
     │
     │ git add
     ▼
Staging Area
     │
     │ git commit
     ▼
Repository
```

---

# The important part for `git bisect`

This is where **working tree** becomes especially important.

When you run:

```bash
git bisect
```

Git repeatedly changes your working tree.

For example:

```text
Before bisect:

HEAD → O
working tree → files from O
```

Git decides to test commit `H`:

```text
HEAD → H
working tree → files from H
```

Then commit `K`:

```text
HEAD → K
working tree → files from K
```

So when you run:

```bash
cat scripts/scan.sh
```

during bisect, you are looking at the **working tree corresponding to the commit Git currently checked out**.

That's why your previous experiment worked:

```text
Git checks out H
        ↓
working tree becomes H
        ↓
wc -l scripts/scan.sh
        ↓
1 line
```

Then:

```text
Git checks out K
        ↓
working tree becomes K
        ↓
wc -l scripts/scan.sh
        ↓
10 lines
```

### Mental model

Think of `HEAD` as:

> **Which commit am I currently looking at?**

And the working tree as:

> **What files from that commit are actually sitting on my disk right now?**

```text
       HEAD
        │
        ▼
      commit H
        │
        │ checkout
        ▼
   Working Tree
   scripts/scan.sh
   README.md
   ...
```

This is also why `git bisect run ./test.sh` works: **Git changes the working tree to each candidate commit, then your script tests those actual files.**


[[Git & Github]]