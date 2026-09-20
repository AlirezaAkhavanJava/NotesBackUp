
`source` is a shell command that **runs a script in the current shell**, instead of starting a new one.

---

### 🧠 In simple terms:

When you do:

```bash
source ~/.bashrc
```

you’re telling your shell:

> “Read and apply everything in this file right now — in _this_ terminal.”

---

### ⚙️ Why it matters

Normally, when you run a script like:

```bash
bash myscript.sh
```

it runs in a **new subshell**, so changes (like PATH updates) disappear after it ends.

But with:

```bash
source myscript.sh
```

or shorthand:

```bash
. myscript.sh
```

it executes _inside_ your current shell — so any variables, PATH changes, or functions stay active.

---

### 🧩 Example

Say you added this to `~/.bashrc`:

```bash
export PATH=$PATH:/home/ethan/scripts
```

To apply it without logging out:

```bash
source ~/.bashrc
```

Now your PATH updates immediately.

---

So basically:

- `bash file.sh` → runs in **a new shell** (temporary).
    
- `source file.sh` → runs in **the current shell** (persistent).

##### Tags : [[2 - Tags/Linux|Linux]]