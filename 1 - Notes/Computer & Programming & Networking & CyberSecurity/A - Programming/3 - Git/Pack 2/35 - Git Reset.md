

### Definition

> **`git reset` moves your branch back to an earlier commit.**

Think:

```text
A ── B ── C ── D
          ↑
         HEAD
```

```bash
git reset B
```

becomes:

```text
A ── B ── C ── D
     ↑
    HEAD
```

So, simply:

> **`git reset` = move back in Git history.**

### The 3 modes

|Command|HEAD|Staging|Working files|
|---|---|---|---|
|`git reset --soft B`|B|Keep changes|Keep changes|
|`git reset B`|B|Unstage changes|Keep changes|
|`git reset --hard B`|B|Discard changes|Discard changes|

The default is **`--mixed`**:

```bash
git reset
```


[[0 - Git 65]]