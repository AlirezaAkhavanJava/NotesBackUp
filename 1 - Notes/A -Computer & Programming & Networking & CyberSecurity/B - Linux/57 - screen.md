

## 🧠 What is `screen`?

- `screen` is a terminal multiplexer like tmux.
    
- Lets you **run multiple terminal sessions inside one window**, detach them, and reattach later.
    
- Works over SSH, keeping processes alive even if you disconnect.
    

---

## 🔑 Core Concepts

|Concept|Description|
|---|---|
|**Session**|A full `screen` instance; can contain multiple windows.|
|**Window**|Like a tab inside a session; can run a shell or program.|
|**Detach/Attach**|Detach: leave session running. Attach: come back to it later.|

---

## 🔀 Basic Commands

### Start screen

```bash
screen
```

or give a session name:

```bash
screen -S mysession
```

### Detach session

```
Ctrl+a d
```

- `Ctrl+a` is the **prefix key**, then `d` detaches.
    

### Reattach session

```bash
screen -r mysession
```

### List sessions

```bash
screen -ls
```

---

### Window Management

|Action|Command (after Ctrl+a)|
|---|---|
|New window|`c`|
|Switch window|`n` (next), `p` (previous)|
|Kill window|`k`|
|Split screen|`S` (horizontal), `|
|Switch regions|`Tab`|

---

### Practical Example

1. SSH into server:
    

```bash
ssh server
screen -S myserver
```

2. Start a long-running process (`./run-server.sh`).
    
3. Detach with `Ctrl+a d`.
    
4. Disconnect SSH — process keeps running.
    
5. Reconnect later:
    

```bash
ssh server
screen -r myserver
```

---

### ⚙️ Notes / Tips

- Older than tmux, so less colorful and flexible.
    
- Good for **simple long-running processes**.
    
- Works on almost all Unix-like systems without installing extra packages.
    
- `screen` uses **Ctrl+a** as its prefix, whereas tmux uses **Ctrl+b**.
    

---



##### Tags : [[2 - Core-concepts/Linux|Linux]]