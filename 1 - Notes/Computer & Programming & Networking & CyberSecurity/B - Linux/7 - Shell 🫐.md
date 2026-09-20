
**Shell**: The **command interpreter** that runs *inside* a terminal. It reads your typed commands, executes them, and shows results.

---

### Shell vs Terminal
| **Terminal** | **Shell** |
|-------------|----------|
| The *app/window* you type in | The *program* that understands your commands |
| Like a phone | Like the person on the other end |

---

### Popular Shells
| Shell | OS | Notes |
|-------|----|-------|
| **Bash** | Linux, macOS (default until 2019) | Most common, widely used in scripts |
| **Zsh** | macOS (default since 2019), Linux | Bash + extras (better autocomplete, themes) |
| **Fish** | Linux, macOS | User-friendly, colorful, easy syntax |
| **PowerShell** | Windows (default), Linux, macOS | Powerful for Windows admin, object-based |
| **Cmd** | Windows | Basic, old-school (still works) |

---

### Example (in any shell)
```bash
echo "Hello, $(whoami)!"
```
→ Output: `Hello, alice!`

---

**Pro Tip**: Upgrade your shell!  
Try `zsh` or `fish` — install once, enjoy forever.

```bash
# On Ubuntu/Debian
sudo apt install zsh
chsh -s /usr/bin/zsh

# Or try fish
sudo apt install fish
fish
```

Your terminal is the stage.  
The **shell** is the actor.

---

**REPL** = **Read-Eval-Print Loop**

A **live, interactive coding environment** where you type code → it runs immediately → you see the result → repeat.

---

### The Loop
```
1. **Read**   → You type code
2. **Eval**   → Computer runs it
3. **Print**  → Shows output
4. **Loop**   → Back to step 1
```

---

### REPL vs Shell vs Terminal

| **Terminal** | **Shell** | **REPL** |
|-------------|----------|--------|
| The *window/app* | Runs *commands* (files, system) | Runs *code* (Python, JS, etc.) |
| `ls`, `cd`, `git` | Bash/Zsh/Fish | `2 + 2` → `4` |
| System-level | Command interpreter | Programming language interpreter |

---

### Popular REPLs
| Language | REPL Name | Try It |
|--------|----------|------|
| **Python** | `python` or `ipython` | `>>> 3 * 7` → `21` |
| **JavaScript** | `node` | `> "Hi".toUpperCase()` → `'HI'` |
| **Ruby** | `irb` | `> [1,2,3].sum` → `6` |
| **R** | `R` console | `> mean(c(1,2,3))` → `2` |
| **Julia** | Julia REPL | `julia> sqrt(16)` → `4.0` |

---

### Example: Python REPL
```bash
$ python
>>> name = "Ada"
>>> print(f"Hello, {name}!")
Hello, Ada!
>>> 
```

---

### Why Use REPL?
- Test code **instantly**
- Learn by experimenting
- Debug step-by-step
- Prototype ideas fast

> **Think of REPL as a calculator for code.**

---

### TL;DR
| Tool | Purpose |
|------|--------|
| **Terminal** | Open the door |
| **Shell** | Talk to the OS |
| **REPL** | Talk to the *language* |

Try one now:  
Open your **terminal** → type `python` → hit Enter → you're in a **REPL**!


- **Terminal**: This is the program/window you type commands into (e.g., GNOME Terminal, Konsole, Alacritty).
    
- **Shell**: This is the program that actually interprets your commands inside the terminal (e.g., Bash, Zsh, Fish).
    

So when you changed your shell to Zsh, your terminal **stays the same**, but now it will start **Zsh instead of Bash** when you open it.

##### Tags : [[2 - Tags/Linux|Linux]]