
Sometimes a program is in _such_ a bad state (or is so malicious) that it doesn't respond to the `SIGINT`, in which case the best option is to use another shell session (new terminal window) to manually [kill](https://www.ibm.com/docs/en/aix/7.3?topic=k-kill-command) the program.

## Syntax

```bash
kill <PID>
```

`PID` stands for "process ID". Every process that's running on your machine has a unique ID. The [ps](https://www.ibm.com/docs/en/zos/3.1.0?topic=jobs-using-ps-command), "process status" command can be used to list the processes running on your machine, and their IDs:

```bash
ps aux
```

The "aux" options just mean "show all processes, including those owned by other users, and show extra information about each process".

---

In Linux, the `kill` command is used to **send signals** to processes — most commonly to terminate them, but it can also send other signals like stop, continue, or custom actions.


### 🧠 Basic Syntax

```bash
kill [options] <pid>
```

- `<pid>` → Process ID (you can find it with `ps`, `top`, or `pgrep`)
    
- By default, `kill` sends **SIGTERM (signal 15)**, which politely asks the process to terminate.
    

---

### 🔀 Common Signals

|Signal|Number|Description|Example|
|---|---|---|---|
|SIGTERM|15|Graceful termination|`kill 1234`|
|SIGKILL|9|Force kill (cannot be caught)|`kill -9 1234`|
|SIGINT|2|Interrupt (like Ctrl+C)|`kill -2 1234`|
|SIGHUP|1|Hangup (reload config, often for daemons)|`kill -HUP 1234`|
|SIGSTOP|19|Pause/suspend process|`kill -STOP 1234`|
|SIGCONT|18|Resume a stopped process|`kill -CONT 1234`|

---

### 🧩 Examples

1. **Graceful termination**
    

```bash
kill 5678
```

2. **Force kill**
    

```bash
kill -9 5678
```

3. **Stop and resume**
    

```bash
kill -STOP 5678
kill -CONT 5678
```

4. **Kill by name (using `pkill`)**
    

```bash
pkill firefox
```

- Sends SIGTERM to all processes named `firefox`.
    

---

### ⚙️ Finding PIDs

```bash
ps aux | grep process_name
```

- Returns PID in the second column.
    

---

### 📝 Notes

- SIGTERM allows the process to **clean up**, delete temp files, close connections.
    
- SIGKILL **cannot be caught** — the process is immediately terminated, no cleanup.
    

----

A **PID** stands for **Process ID** — a unique number assigned by the operating system to every running process.


### 🧠 Key Points about PIDs

- Each process has a **unique PID** while it’s running.
    
- The PID lets the OS and users **identify, control, or signal** that process.
    
- PIDs are assigned sequentially by the kernel (usually starting from 1).
    

---

### 🔍 Find PIDs

1. **Using `ps`**
    

```bash
ps aux | grep firefox
```

- The second column in `ps aux` output is the PID.
    

2. **Using `pidof`**
    

```bash
pidof firefox
```

- Returns the PID(s) of all running instances of `firefox`.
    

3. **Using `top` or `htop`**
    

- Shows live processes with their PIDs.
    

---

### ⚙️ Using PIDs

- **Kill a process**: `kill <PID>`
    
- **Check memory or CPU usage**: `top` or `ps -p <PID>`
    
- **Send signals** (interrupt, stop, continue) with `kill` or `kill -SIGNAL <PID>`
    

---

### 🧩 Special PIDs

- `1` → Usually the **init** or **systemd** process (ancestor of all processes)
    
- `$$` → In a shell script, this is the **PID of the current shell**
    
- `$!` → PID of the **last background process**
    


##### Tags : [[2 - Core-concepts/Linux|Linux]]