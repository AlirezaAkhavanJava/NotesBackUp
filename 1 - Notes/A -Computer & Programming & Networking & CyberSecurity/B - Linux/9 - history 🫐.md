
In Unix/Linux, the `history` command is used to **view a list of previously executed commands** in your shell.

---

### **1. Basic Usage**

```bash
history
```

- Displays a numbered list of commands you typed in the current shell session (and sometimes previous sessions, depending on configuration).
    

Example output:

```
1  ls
2  cd /home/ethan
3  mkdir projects
4  nano test.txt
```

---

### **2. Common Options**

- **Run a specific previous command**:
    

```bash
!3
```

This reruns command number 3 (`mkdir projects` in the example).

- **Search command history**:
    

```bash
history | grep "cd"
```

Shows only commands that include `cd`.

- **Clear history**:
    

```bash
history -c
```

Erases your shell history.

---

### **3. Quick Analogy**

`history` is like a **time machine for your terminal**—you can see everything you did and even repeat it without retyping.


##### Tag : [[2 - Core-concepts/Linux|Linux]]