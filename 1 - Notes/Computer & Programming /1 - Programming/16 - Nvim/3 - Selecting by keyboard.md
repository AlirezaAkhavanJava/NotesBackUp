
In **LazyVim/Neovim**, you usually want **Visual Line mode** for selecting multiple lines.

### Select multiple whole lines

1. Put your cursor on the first line.
    
2. Press:
    

```text
V
```

`V` = **Visual Line mode**

3. Move with `j` / `k`:
    

```text
V
j
j
j
```

This selects the current line + 3 lines below it.

### Useful keyboard controls

|Key|Action|
|---|---|
|`V`|Select entire current line|
|`j`|Extend selection downward|
|`k`|Extend selection upward|
|`d`|Delete selected lines|
|`y`|Yank/copy selected lines|
|`c`|Replace selected lines|
|`>`|Indent selection|
|`<`|Unindent selection|
|`Esc`|Exit selection|

### Select from current line to a specific line

For example, select **10 lines downward**:

```text
V
9j
```

Because the current line counts as the first line.

### Select characters across multiple lines

If you don't want whole lines, use:

```text
v
```

This is **Visual Character mode**.

Example:

```text
v
j
j
l
```

This lets the selection follow the cursor character-by-character, even across lines.

### Select a rectangular/block area

For column-based selection:

```text
Ctrl-v
```

This enters **Visual Block mode**.

For example:

```text
Ctrl-v
j
j
l
l
```

selects a rectangular block of text.

**Mental model:**

```text
v       → characters
V       → whole lines
Ctrl-v  → rectangular columns
```

These are native Vim motions, so they work in LazyVim because LazyVim is built on Neovim.


[[Vim]]