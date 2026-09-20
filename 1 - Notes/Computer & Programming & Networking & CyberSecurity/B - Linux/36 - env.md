
The `env` command in Linux is used to **view, set, or run a command with modified environment variables**.

### 🔹 Basic Uses

1. **Show all environment variables**
    
    ```bash
    env
    ```
    
    → Lists all environment variables currently set in your shell.
    
2. **Run a command with a temporary environment variable**
    
    ```bash
    env VAR=value command
    ```
    
    Example:
    
    ```bash
    env NAME=Ethan echo $NAME
    ```
    
    → Runs `echo` with `NAME` temporarily set to `Ethan` (not saved in the session).
    
3. **Clear all environment variables before running a command**
    
    ```bash
    env -i command
    ```
    
    → Runs the command in a clean environment (`-i` = ignore inherited variables).
    
4. **Set multiple variables and run**
    
    ```bash
    env VAR1=value1 VAR2=value2 myscript.sh
    ```
    

### 🔹 Common Example

```bash
env PATH=/custom/bin:$PATH ./program
```

→ Runs `program` using a modified `PATH`.


---

Environment variables are **key–value pairs** stored in your system or shell that define the environment in which programs run.

### 🔹 Simple idea

They’re like _global settings_ that programs use to know things such as:

- Where to find files
    
- Which language to use
    
- Who the current user is
    

### 🔹 Examples

|Variable|Meaning|Example value|
|---|---|---|
|`PATH`|Directories to search for commands|`/usr/local/bin:/usr/bin:/bin`|
|`HOME`|Current user’s home directory|`/home/ethan`|
|`USER`|Current username|`ethan`|
|`SHELL`|Default shell program|`/bin/bash`|
|`LANG`|Language/locale setting|`en_US.UTF-8`|

### 🔹 View all environment variables

```bash
env
```

or

```bash
printenv
```

### 🔹 Access or create one

```bash
echo $HOME        # View a variable
export NAME=Ethan # Create/set a new one
```

### 🔹 Temporary vs permanent

- **Temporary** → only for the current shell:
    
    ```bash
    export TEST=123
    ```
    
- **Permanent** → add it to `~/.bashrc` or `~/.profile`:
    
    ```bash
    echo 'export TEST=123' >> ~/.bashrc
    ```
    

---

# PATH

**`PATH` is one of the most important **environment variables** in Linux (and Unix-like systems).

### 🔹 What it does

It tells the shell **where to look for executables** when you type a command.

For example, when you type:

```bash
ls
```

the shell doesn’t know where `ls` is — it searches the directories listed in `$PATH` (in order) until it finds it.

---

### 🔹 View your PATH

```bash
echo $PATH
```

You’ll see something like:

```
/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
```

Each directory is separated by a colon `:`.

---

### 🔹 Add a directory to PATH (temporary)

```bash
export PATH=$PATH:/home/ethan/scripts
```

→ Now executables inside `/home/ethan/scripts` can be run directly.

---

### 🔹 Make it permanent

Add that line to your `~/.bashrc` or `~/.profile`:

```bash
echo 'export PATH=$PATH:/home/ethan/scripts' >> ~/.bashrc
```

---

### 🔹 Check where a command is found

```bash
which ls
```

or

```bash
type ls
```



##### Tags :  [[2 - Tags/Linux|Linux]]