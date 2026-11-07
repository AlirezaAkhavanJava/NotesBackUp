


In **LazyVim / Neovim**, page movement uses Vim's standard keybindings:

|Action|Key|
|---|---|
|Page down|`Ctrl + d`|
|Page up|`Ctrl + u`|
|Half-page down|`Ctrl + d`|
|Half-page up|`Ctrl + u`|
|Full page down|`Ctrl + f`|
|Full page up|`Ctrl + b`|
|Move cursor to middle of screen|`zz`|
|Move cursor to top of screen|`zt`|
|Move cursor to bottom of screen|`zb`|

### The important ones

```text
Ctrl+d    ↓
Ctrl+u    ↑
```

These are generally the most comfortable for coding because they move about half a screen while keeping some context visible.

### If you want actual PageUp/PageDown keys

Your keyboard's:

```text
PageDown  →  Page Down
PageUp    →  Page Up
```

usually work directly in Neovim/LazyVim as well.

**My recommendation:** use `Ctrl+d` / `Ctrl+u` for normal navigation, and `Ctrl+f` / `Ctrl+b` when you want to jump through the file faster.


---
For **line-by-line navigation** in LazyVim:

|Key|Action|
|---|---|
|`j`|Move **down** one line|
|`k`|Move **up** one line|
|`h`|Move **left**|
|`l`|Move **right**|

So the basic movement is:

```text
        k
        ↑
    h ←   → l
        ↓
        j
```

### Useful line navigation

```text
j       ↓ one line
k       ↑ one line
0       beginning of line
^       first non-whitespace character
$       end of line
```

For example:

```text
10 | public class Main {
11 |     public static void main(String[] args) {
12 |         System.out.println("Hello");
13 |     }
14 | }
```

If your cursor is on line `12`:

- `j` → line `13`
    
- `k` → line `11`
    
- `0` → column 1
    
- `^` → first non-space character
    
- `$` → end of line
    

### Faster line movement

```text
5j      move down 5 lines
5k      move up 5 lines
10j     move down 10 lines
10k     move up 10 lines
```

This is one of the core Vim navigation concepts: **numbers multiply motions**.

[[Vim]]