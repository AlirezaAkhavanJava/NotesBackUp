Upgrade your shell!  
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


----
To switch back to your previous shell (probably Bash), just run:

```bash
chsh -s /bin/bash
```

Then **log out and log back in** (or restart your terminal).

After that, you can confirm with:

```bash
echo $SHELL
```

It should show `/bin/bash`.

If you want, you can also **temporarily switch shells** without changing defaults by just typing `bash` or `zsh` in your terminal.

---

In Unix/Linux, `chsh` stands for **“change shell”**. It’s a command used to **change your login shell** (the program that runs when you open a terminal).



### **1. Basic Usage**

```bash
chsh -s /bin/zsh
```

- `-s` → specify the shell you want.
    
- `/bin/zsh` → path to the new shell.
    
- After running this, you usually need to **log out and log back in** for it to take effect.
    



### **2. How It Works**

- Your default shell is stored in `/etc/passwd` for your user account.
    
- `chsh` updates that entry to point to a new shell.
    



### **3. Common Shell Paths**

- Bash: `/bin/bash`
    
- Zsh: `/bin/zsh`
    
- Fish: `/usr/bin/fish`
    



### **4. Quick Analogy**

`chsh` is like **changing the language your assistant speaks**: your terminal will still work, but the commands, prompts, and features may behave differently depending on the shell.


---

If you want to **change the shell only for the current terminal session** (i.e., locally, without affecting the default shell for your user), you can just run the shell command directly:

```bash
zsh
```

or, to go back to Bash:

```bash
bash
```

- This only lasts until you **close the terminal**.
    
- It doesn’t require `sudo` or `chsh`.
    
- You can even run `zsh` inside Bash, then `bash` inside Zsh—it’s like nesting shells.
    



##### Tags : [[2 - Core-concepts/Linux|Linux]]