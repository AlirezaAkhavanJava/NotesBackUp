

### 🧭 **1. Temporary (only for this session)**

Use `export`:

```bash
export PATH=$PATH:/home/ethan/myprograms
```

Now, any executable in `/home/ethan/myprograms` can be run directly:

```bash
mytool
```

🧨 But — this lasts **only until you close the terminal**.

---

### 🗿 **2. Permanent (saved forever)**

Edit your shell config file, for example:

```bash
nano ~/.bashrc
```

Add this line at the end:

```bash
export PATH=$PATH:/home/ethan/myprograms
```

Then reload the file:

```bash
source ~/.bashrc
```

Now it’s always active every time you log in.

---

### 💡 Quick check

Run:

```bash
echo $PATH
```

You should see `/home/ethan/myprograms` added at the end.




##### Tags : [[2 - Tags/Linux|Linux]]