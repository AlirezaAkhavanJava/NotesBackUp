
`chown` (change owner) in Linux is used to change **the owner and/or group** of a file or directory.

### 🧠 Syntax:

```bash
chown [OPTIONS] OWNER[:GROUP] FILE
```

### 🔹 Examples:

|Command|Meaning|
|---|---|
|`chown ethan file.txt`|Change owner of `file.txt` to `ethan`.|
|`chown ethan:devs file.txt`|Change owner to `ethan` and group to `devs`.|
|`chown :devs file.txt`|Change only the group to `devs`.|
|`sudo chown -R ethan /var/www`|Recursively change ownership of `/var/www` and everything inside it.|

### 🔸 Useful options:

- `-R` → recursive (apply to all files/subdirectories)
    
- `-v` → verbose (show what’s being changed)
    
- `--reference=FILE` → use ownership from another file
    

Example:

```bash
sudo chown -Rv ethan:ethan /home/ethan/Documents
```



---

`chgrp` (change group) changes **only the group ownership** of a file or directory — not the user/owner.

### 🧠 Syntax:

```bash
chgrp [OPTIONS] GROUP FILE
```

### 🔹 Examples:

|Command|Meaning|
|---|---|
|`chgrp devs file.txt`|Change group of `file.txt` to `devs`.|
|`sudo chgrp -R devs /var/www`|Recursively change group of `/var/www` and everything inside it to `devs`.|

### 🔸 Useful options:

- `-R` → recursive
    
- `-v` → verbose (show what’s changed)
    
- `--reference=FILE` → use the same group as another file
    

### ⚖️ Difference from `chown`:

- `chown` → changes **user** (and optionally group).
    
- `chgrp` → changes **only the group**.
    

Example comparison:

```bash
sudo chown ethan:devs file.txt   # changes both
sudo chgrp devs file.txt         # changes only group
```


##### Tags : [[2 - Core-concepts/Linux|Linux]]