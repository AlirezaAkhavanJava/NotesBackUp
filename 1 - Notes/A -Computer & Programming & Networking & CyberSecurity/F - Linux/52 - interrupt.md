In Linux (and general programming), an **interrupt** is a signal that tells a process to **stop what it’s doing**, either temporarily or permanently.

---

### 🧠 Types of Interrupts

1. **Keyboard interrupts**
    
    - Most common: `Ctrl+C`
        
    - Sends **SIGINT** (signal 2) to the foreground process.
        
    - Default behavior: terminate the program.  
        Example:
        
    
    ```bash
    ping google.com
    # Press Ctrl+C
    ```
    
    Output:
    
    ```
    ^C
    --- ping statistics ---
    ```
    
2. **Terminal stop**
    
    - `Ctrl+Z` sends **SIGTSTP**, which suspends the process (doesn’t kill it).  
        Example:
        
    
    ```bash
    sleep 100
    # Press Ctrl+Z
    jobs   # shows suspended process
    fg %1  # bring it back to foreground
    ```
    
3. **Signals from other processes**
    
    - `kill -SIGINT <pid>` → same as `Ctrl+C`
        
    - `kill -SIGTERM <pid>` → polite request to terminate
        
    - `kill -9 <pid>` → force kill (`SIGKILL`)
        

---

### 🔀 Handling Interrupts in Scripts

You can trap signals to clean up or do something before exiting:

```bash
#!/bin/bash
trap "echo 'Interrupted! Exiting.'; exit" SIGINT

echo "Running... Press Ctrl+C to stop"
while true; do
  sleep 1
done
```

- Pressing Ctrl+C triggers the **trap**, prints a message, then exits.
    

---

### ⚙️ Why it matters

- Interrupts let users **stop long-running or misbehaving programs**.
    
- Signals allow scripts to **handle cleanup** (like deleting temporary files) instead of crashing.
    



##### Tags : [[2 - Core-concepts/Linux|Linux]]