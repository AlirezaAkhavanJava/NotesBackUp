

**Redirection** in Linux controls where a program’s input and output go — instead of always using the keyboard (stdin) and screen (stdout/stderr), you can **redirect** them to or from files, or even between commands.

---

### 🧠 The 3 Standard Streams

|Stream|Number|Description|Default Target|
|---|---|---|---|
|`stdin`|`0`|Input to the program|Keyboard|
|`stdout`|`1`|Normal output|Screen|
|`stderr`|`2`|Error messages|Screen|

---

### 🔀 Basic Redirections

|Operator|Meaning|Example|
|---|---|---|
|`>`|Redirect stdout (overwrite file)|`ls > files.txt`|
|`>>`|Redirect stdout (append)|`ls >> files.txt`|
|`<`|Redirect stdin (read from file)|`cat < input.txt`|
|`2>`|Redirect stderr|`ls /root 2> errors.txt`|
|`2>>`|Append stderr|`ls /root 2>> errors.txt`|

---

### 🔄 Combine stdout & stderr

|Example|Meaning|
|---|---|
|`command > all.txt 2>&1`|Send both stdout and stderr to `all.txt`|
|`command &> all.txt`|Same as above (Bash shortcut)|

---

### 🕳️ Discard output

```bash
command > /dev/null 2>&1
```

- `/dev/null` is a “black hole” — it deletes anything written to it.
    

---

### 🧩 Input redirection + output redirection

```bash
sort < unsorted.txt > sorted.txt
```

Reads from `unsorted.txt` (stdin), writes to `sorted.txt` (stdout).

---

### 🧪 Advanced: Custom file descriptors

You can create your own streams:

```bash
exec 3> output.log
echo "Hello" >&3
exec 3>&-
```

- Opens FD 3 for writing
    
- Writes to it
    
- Closes it
    

---

 **Process Substitution** — a more advanced form of redirection. It lets you use **commands as input or output files**.



### 🧠 Concept

Normally, redirection reads/writes to **files**:

```bash
sort < file1.txt
```

With process substitution, you can make a **command behave like a file**:

```bash
diff <(command1) <(command2)
```

Here:

- `<(command1)` → stdout of `command1` becomes a “temporary file”
    
- `<(command2)` → same for `command2`
    
- `diff` reads from these as if they were files
    

---

### 🔀 Syntax

|Type|Meaning|
|---|---|
|`<(command)`|Makes command’s output look like a file (for stdin)|
|`>(command)`|Sends what would normally go to a file **into a command**|

---

### 🧩 Examples

#### Compare outputs of two commands

```bash
diff <(ls dir1) <(ls dir2)
```

- Compares directory listings **without creating actual files**.
    

#### Send stdout to another command

```bash
echo "Hello World" > >(tee out.txt)
```

- `tee` writes to `out.txt` and still displays on screen.
    

#### Sort and process at the same time

```bash
comm -12 <(sort file1.txt) <(sort file2.txt)
```

- `comm -12` finds **common lines**
    
- Process substitution lets `comm` read **sorted outputs directly**.
    

---

### ⚙️ Why it’s useful

- No temporary files needed
    
- Works with commands that expect **file arguments**
    
- Cleaner, faster, more script-friendly
    

---


##### Tags : [[2 - Tags/Linux|Linux]]