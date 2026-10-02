

## 1️⃣ Aliases

An **alias** is a shortcut for a command (or group of commands) so you don’t have to type long stuff repeatedly.

### Syntax

```bash
alias shortname='long command here'
```

### Example

```bash
alias ll='ls -alF'
alias gs='git status'
alias rmf='rm -rf'
```

- After this, typing `ll` runs `ls -alF` automatically.
    

---

### Remove an alias temporarily

```bash
unalias ll
```

---

## 2️⃣ `.bashrc`

- `.bashrc` is a **shell configuration file** in your home directory (`~/.bashrc`).
    
- It runs **every time you start an interactive bash shell**.
    
- You can put aliases, environment variables, functions, or scripts in it.
    

### Example: Add aliases

Edit `~/.bashrc` (with nano, vim, etc.)

```bash
nano ~/.bashrc
```

Add at the end:

```bash
# My custom aliases
alias ll='ls -alF'
alias gs='git status'
```

Then save and exit.

---

### 3️⃣ Apply changes without restarting terminal

```bash
source ~/.bashrc
```

- Or shorthand:
    

```bash
. ~/.bashrc
```

- Now your new aliases or environment variables are active.
    

---

### ⚡ Tips

- Always put custom stuff **at the end** of `.bashrc` to avoid overwriting system defaults.
    
- You can also use `.bash_aliases` (some distros load it automatically from `.bashrc`).
    

---


##### Tags : [[2 - Tags/Linux|Linux]]