


## 🧠 What is tmux?

- **tmux** = terminal multiplexer.
    
- Lets you **run multiple terminal sessions inside one window**, detach them, and reattach later.
    
- Works over SSH, so you can leave long-running processes alive even after disconnecting.
    

---

## 🔑 Core Concepts

|Concept|Description|
|---|---|
|**Session**|A full tmux instance; can contain multiple windows.|
|**Window**|Like a tab inside a session; can run a program or shell.|
|**Pane**|Split a window into multiple sections (horizontal/vertical).|
|**Detach/Attach**|Detach: leave session running. Attach: come back to it later.|

---

## 🔀 Basic Commands

### Start tmux

```bash
tmux
```

or give a session name:

```bash
tmux new -s mysession
```

### Detach session

```bash
Ctrl+b d
```

- `Ctrl+b` is the **prefix key**, then `d` detaches.
    

### Reattach session

```bash
tmux attach -t mysession
```

### List sessions

```bash
tmux ls
```

---

### Window & Pane Management

|Action|Command (after Ctrl+b)|
|---|---|
|New window|`c`|
|Switch window|`n` (next), `p` (previous), `0-9` (specific)|
|Split horizontally|`"`|
|Split vertically|`%`|
|Move between panes|Arrow keys (after Ctrl+b)|
|Resize pane|`Ctrl+b` then hold `Ctrl` + arrow keys|

---

### Practical Example

1. SSH into a server:
    

```bash
ssh server
tmux new -s myserver
```

2. Start a long-running process (e.g., `./run-server.sh`).
    
3. Detach with `Ctrl+b d`.
    
4. Disconnect SSH — process keeps running.
    
5. Reconnect later:
    

```bash
ssh server
tmux attach -t myserver
```

---

### ⚙️ Tips

- **Copy/Paste**: `Ctrl+b [` enters copy mode; move cursor, press Enter to copy, `Ctrl+b ]` to paste.
    
- **Customization**: You can tweak `~/.tmux.conf` to change colors, keybindings, default layouts, etc.
    
- **Persistence**: Ideal for long-running builds, servers, or scripts you don’t want interrupted by SSH disconnects.
    

---



##### Tags : [[2 - Tags/Linux|Linux]]