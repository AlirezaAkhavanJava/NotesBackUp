
`man` stands for **manual**. It’s the built-in documentation system in Linux and Unix.

---

### 🧠 How it works

When you type:

```bash
man ls
```

it opens the **manual page** for `ls`, showing:

- **Name:** what the command/program is
    
- **Synopsis:** syntax and options
    
- **Description:** what it does
    
- **Options:** flags like `-l`, `-a`
    
- **Examples** (sometimes)
    

Use **arrow keys** or `PageUp/PageDown` to scroll. Press `q` to quit.

---

### 🧩 Quick examples

```bash
man bash       # manual for the shell itself
man chmod      # how to change file permissions
man man        # yes, man has a manual too
```

---

### 🔍 Tips

- Search inside man: `/pattern` (like `/permissions`)
    
- List all sections of a command:
    

```bash
man -f ls   # shows a short description
man -k copy # searches man pages for “copy”
```



##### Tags : [[2 - Core-concepts/Linux|Linux]]