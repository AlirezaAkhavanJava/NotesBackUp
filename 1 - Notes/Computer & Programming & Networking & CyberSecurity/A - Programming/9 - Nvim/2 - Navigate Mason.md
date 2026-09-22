
In **LazyVim's Mason UI**, Mason uses a Telescope-like interface.

### Search

Open Mason:

```text
:Mason
```

Then simply start typing:

```text
spring
```

Mason will filter the package list.

### Navigate the results

```text
↑ / Ctrl+k    previous result
↓ / Ctrl+j    next result
Enter         select/install
Esc            close
```

You can also use:

```text
Ctrl+u        scroll up
Ctrl+d        scroll down
```

### Example

```text
:Mason
```

Then type:

```text
java
```

You'll get filtered results such as:

```text
jdtls
java-debug-adapter
java-test
```

Use:

```text
Ctrl+j
Ctrl+k
```

to move between them, then:

```text
Enter
```

to select the highlighted package.

### Important LazyVim/Telescope pattern

You'll see this same navigation style throughout LazyVim:

```text
Ctrl+j   ↓
Ctrl+k   ↑
Ctrl+d   page down
Ctrl+u   page up
Enter    confirm
Esc      close
```

So once you learn these, **Mason, Telescope, file search, command search, etc.** become much easier to navigate.

---
> switching between the Mason search input and the results list**.

In Mason:

### Search → results

1. Open Mason:
    

```vim
:Mason
```

2. Press:
    

```text
/
```

This focuses the **search/filter input**.

3. Type your search:
    

```text
java
```

4. Press:
    

```text
Esc
```

This exits the search input and returns focus to the **package list**.

5. Now navigate:
    

```text
j / ↓     next result
k / ↑     previous result
```

### In short

```text
:Mason
   ↓
/          → enter search
   ↓
java       → filter
   ↓
Esc        → leave search
   ↓
j / k      → navigate results
```

If `Esc` doesn't return focus correctly in your particular LazyVim/Mason version, tell me what happens when you press it and I can give you the exact keybinding.

[[Vim]]