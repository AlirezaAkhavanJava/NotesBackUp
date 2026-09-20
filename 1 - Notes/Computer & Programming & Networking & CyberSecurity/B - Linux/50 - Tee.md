
### 🧰 `tee` Command — “Split stdout into two streams”

Normally, when you redirect with `>`, output goes **only** to a file — you don’t see it on screen.  
`tee` fixes that by letting you **see and save** at once.

---

### 🧠 Syntax

```bash
command | tee [options] filename
```

- Takes **stdin** (usually from a pipe)
    
- Sends it to **stdout** (screen)
    
- Also writes it to the specified file
    

---

### 📄 Example

```bash
ls | tee files.txt
```

You’ll see the directory listing **on screen**, and it’s also saved in `files.txt`.

---

### ➕ Append mode

Use `-a` to append instead of overwrite:

```bash
ls | tee -a log.txt
```

---

### ⚙️ Combine with other tools

```bash
grep "error" app.log | tee errors.txt | wc -l
```

- `grep` finds lines with “error”
    
- `tee` saves them to `errors.txt`
    
- `wc -l` counts them
    
- You still see them live in the terminal
    

---

### 🔒 Useful in scripts

```bash
#!/bin/bash
make 2>&1 | tee build.log
```

Captures both stdout and stderr to a log file **while showing progress live**.


##### Tags : [[2 - Tags/Linux|Linux]]