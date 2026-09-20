
# Standard Error

["Standard Error"](https://en.wikipedia.org/wiki/Standard_streams#Standard_error_%28stderr%29), usually called "stderr", is a data stream just like standard output, but is intended to be used for _error_ messages.

It's a separate stream so that you can redirect it to a different place if need be, but by default, it prints to your terminal just like stdout.

## Redirecting Streams

You can redirect stdout and stderr to different places using the `>` and `2>` operators. `>` redirects stdout, and `2>` redirects stderr.

### Redirect stdout to a File

```bash
echo "Hello world" > hello.txt
cat hello.txt
# Hello world
```

### Redirect stderr to a File

```bash
cat doesnotexist.txt 2> error.txt
cat error.txt
# cat: doesnotexist.txt: No such file or directory
```

In this example, `cat` is used to intentionally generate an error message (since the file doesn't exist), which is then redirected to `error.txt`.


----
**Standard Error (stderr)** — stream number **2** — is where programs send **error messages** or diagnostic info, separate from normal output (stdout).

### 🧠 Purpose

- Keeps **errors** separate from normal results.
    
- Prevents errors from being mixed into data pipelines.
    
- Useful for logging and debugging.
    

Example:

```bash
ls /root
```

Output:

```
ls: cannot open directory '/root': Permission denied
```

That line is printed to **stderr (2)**, not stdout.

---

### 🔀 Redirecting stderr

|Action|Syntax|Meaning|
|---|---|---|
|Redirect only stderr|`2>`|Overwrite file|
|Append stderr|`2>>`|Append to file|
|Redirect both stdout + stderr|`> file 2>&1`|Merge both|

Examples:

```bash
ls /root 2> errors.txt        # only errors
ls /root /tmp > out.txt 2> err.txt  # separate files
ls /root > all.txt 2>&1       # combine both
```

---

### 🧩 Why it matters

If you run:

```bash
ls /root | wc -l
```

You’ll notice `wc` counts only valid (stdout) output — **errors are ignored**, because they’re on stderr.

---

### 🕳️ To discard errors

```bash
ls /root 2> /dev/null
```

No error messages shown — stderr is “swallowed” by `/dev/null`.


##### Tags : [[2 - Core-concepts/Linux|Linux]]