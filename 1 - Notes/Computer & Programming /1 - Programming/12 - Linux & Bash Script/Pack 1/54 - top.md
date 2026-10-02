


### 🧠 `top`

- **Command:** `top`
    
- **Purpose:** Shows **real-time system info** — CPU, memory, and running processes.
    
- **Features:**
    
    - Dynamic list of processes sorted by CPU usage.
        
    - Shows PID, user, CPU%, memory%, running time, command, etc.
        
    - Can interactively **kill or renice** processes (press `k` for kill, `r` for renice inside top).
        
- **Interface:** Text-based, keyboard-driven, but a bit clunky.
    
- **Example:**
    

```bash
top
```

- Press `q` to quit.
    

---

### 🧠 `htop`

- **Command:** `htop` (may require installation: `sudo apt install htop`)
    
- **Purpose:** Like `top`, but **more user-friendly**.
    
- **Features:**
    
    - Color-coded display of CPU, memory, swap usage.
        
    - Interactive: **scroll up/down**, **sort by any column**, **kill or renice with function keys**.
        
    - Supports **tree view** of processes (`F5`).
        
- **Interface:** Cleaner, easier to navigate with arrows and function keys.
    
- **Example:**
    

```bash
htop
```

- Use `F10` to quit.
    

---

### 🔄 Comparison

|Feature|top|htop|
|---|---|---|
|Ease of use|Basic|User-friendly, colorful|
|Navigation|Limited|Scrollable, interactive|
|Sorting|Limited|Sort by any column dynamically|
|Process tree|No|Yes (`F5`)|
|Installation|Usually pre-installed|Often needs install|

---

### 🧩 Practical Tips

- **Find a process PID:** Use `top` or `htop` → PID column.
    
- **Kill a process:** `kill <PID>` or inside `htop`, select process → `F9`.
    
- **Monitor system resources:** Watch CPU/memory usage in real-time.
    

---


## 1️⃣ `top` Output

When you run `top`, you usually see **two sections**:

### **A. Summary (System Info) – top few lines**

Example:

```bash
top - 12:15:01 up  2:35,  2 users,  load average: 0.42, 0.30, 0.25
Tasks: 205 total,   1 running, 204 sleeping,   0 stopped,   0 zombie
%Cpu(s):  5.0 us,  1.0 sy,  0.0 ni, 93.0 id,  0.5 wa,  0.0 hi,  0.5 si,  0.0 st
KiB Mem :  8173820 total, 4123456 free, 3012344 used, 1038020 buff/cache
KiB Swap:  2097148 total, 2097148 free,       0 used. 4876540 avail Mem
```

- **Load average** → CPU load over 1, 5, 15 minutes
    
- **Tasks** → total processes, running, sleeping, stopped, zombie
    
- **%Cpu(s)** → CPU usage breakdown:
    
    - `us` → user processes
        
    - `sy` → system/kernel
        
    - `id` → idle
        
    - `wa` → waiting for I/O
        
    - `hi/si/st` → hardware/software interrupts / stolen (VM)
        
- **Memory/Swap** → total, free, used, buffers/cache
    

---

### **B. Process List – rest of the screen**

Columns typically look like:

|Column|Meaning|
|---|---|
|PID|Process ID|
|USER|Owner of the process|
|PR|Priority|
|NI|Nice value (affects priority)|
|VIRT|Virtual memory used|
|RES|Resident memory (RAM used)|
|SHR|Shared memory|
|S|Process state (R=running, S=sleeping, T=stopped, Z=zombie)|
|%CPU|CPU usage|
|%MEM|Memory usage|
|TIME+|Total CPU time used|
|COMMAND|Process name/command|

---

## 2️⃣ `htop` Output

- **Top bar**: CPU bars (color-coded), memory, swap, load average.
    
- **Process list**: Same columns as `top`, but scrollable and interactive.
    
- **Color codes**:
    
    - CPU green → user processes
        
    - Red → kernel processes
        
    - Blue → low priority / nice
        
- You can **sort by any column**, scroll, and see **tree view** (`F5`) to see parent/child relationships.
    

---

### 3️⃣ How to use the info

1. **Find resource-heavy processes**
    
    - Sort by `%CPU` or `%MEM` → find the culprit.
        
2. **Check memory usage**
    
    - `RES` vs `VIRT` → how much RAM vs total allocated memory.
        
3. **Check CPU load**
    
    - `%Cpu(s)` or CPU bars → are cores maxed out?
        
4. **Manage processes**
    
    - Note the PID → use `kill <PID>` or in `htop` `F9` to terminate.
        

---


##### Tags : [[2 - Tags/Linux|Linux]]