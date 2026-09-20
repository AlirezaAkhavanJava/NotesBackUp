
In Linux/Unix, a **flag** (also called an **option** or **switch**) is a **special argument you pass to a command to modify its behavior**.

---

### 🧠 How it looks

Flags usually start with:

- `-` (single dash) for **short flags**, e.g., `-l`
    
- `--` (double dash) for **long flags**, e.g., `--all`
    

Example with `ls`:

```bash
ls -l       # long listing format
ls -a       # show hidden files
ls -la      # combine both
ls --all    # same as -a
```

---

### 🧩 Rules

1. **Single-character flags** can often be combined:
    

```bash
ls -la   # same as ls -l -a
```

2. **Long flags** usually need `--` and can’t be combined:
    

```bash
ls --all --human-readable
```

3. Flags **change how the command behaves** — they don’t usually specify files (files are arguments, not flags).
    



### 🧠 Quick tip

Think of flags as **little switches you flip** to make a command do exactly what you want.



##### Tags : [[2 - Core-concepts/Linux|Linux]]