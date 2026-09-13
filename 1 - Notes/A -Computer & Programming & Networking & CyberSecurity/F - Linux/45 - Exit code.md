

In Linux (and programming generally), **exit codes** are numeric values returned by a process when it finishes running — they tell the OS (and you) _how_ the process ended.


[Exit codes](https://en.wikipedia.org/wiki/Exit_status) (sometimes called "return codes" or "status codes") are how programs communicate back whether they ran successfully or not.

**`0` is the exit code for success. Any other exit code is an error**. 9 times out of 10, if a non-zero exit code is returned (meaning an error) it will be `1`, which is the "catch-all" error code.

Programs that call other programs use error codes to figure out if execution was successful. For example, if the Boot.dev server program exits with a non-zero exit code, we have another program that will automatically restart it and log the error.

In a shell, you can access the exit code of the last program you ran with the question mark variable (`$?`). For example, if you run a program that exits with a non-zero exit code, you can see what it was with the `echo` command:

```bash
ls ~
echo $?
# 0
```


```bash
ls /does/not/exist
echo $?
# non-zero (depends on your OS)
```

---

You can use the `unset` command to unset an environment variable:

```bash
unset ENV_VAR_NAME
```

Alternatively, you can set the environment variable to an empty string:

```bash
export ENV_VAR_NAME=""
```


---

### 🧠 Basic idea

- Every program, when it ends, gives back an **exit status code** to the shell.
    
- By convention:
    
    - `0` → ✅ success
        
    - Non-zero → ❌ some kind of failure or abnormal termination
        

---

### 📊 Common Exit Codes

|Code|Meaning|Example|
|---|---|---|
|`0`|Success|`echo "Done"`|
|`1`|General error|`ls /not/here`|
|`2`|Misuse of shell builtins|`exit` used wrong|
|`126`|Command found but not executable|permissions issue|
|`127`|Command not found|typo in command name|
|`128`|Invalid exit argument|e.g. `exit -1`|
|`130`|Script terminated by Ctrl+C|signal `SIGINT`|
|`137`|Killed (usually `SIGKILL`)|e.g. `kill -9 <pid>`|
|`139`|Segmentation fault|typical crash in C programs|
|`255`|Exit status out of range|invalid exit code|

---

### 🧩 How to Check Exit Codes

After running a command:

```bash
echo $?
```

Example:

```bash
ls /fakepath
echo $?
# Output: 2  (means "No such file or directory")
```

---

### 🧰 Custom Exit Codes in Scripts

You can set them yourself:

```bash
#!/bin/bash
if [ ! -f myfile.txt ]; then
  echo "File missing!"
  exit 1
fi
echo "All good!"
exit 0
```

---



Exit codes are **directly tied** to how shell conditionals work — they control what runs next.

### 🧠 How Shell Uses Exit Codes

#### ✅ `&&` → runs next command **only if previous succeeded**

```bash
mkdir test && cd test
```

- `cd test` runs **only** if `mkdir test` returned `0` (success).
    

#### ❌ `||` → runs next command **only if previous failed**

```bash
make || echo "Build failed"
```

- If `make` returns **non-zero**, the message is shown.
    

---

### 🔁 Combining Both

```bash
mkdir build && echo "Created" || echo "Failed"
```

> Careful: if `echo "Created"` runs successfully, it returns `0`, so the `||` part won’t execute even if `mkdir` failed — use `if` instead for reliability.

---

### 🧩 `if` Uses Exit Codes Too

```bash
if ls /tmp; then
  echo "It exists"
else
  echo "Not found"
fi
```

- `if` checks the exit code of `ls`:
    
    - `0` → true branch
        
    - non-zero → false branch
        

---

### 🕹️ Manually Checking

```bash
command
status=$?
if [ $status -ne 0 ]; then
  echo "Command failed with code $status"
fi
```


##### Tags : [[2 - Core-concepts/Linux|Linux]]