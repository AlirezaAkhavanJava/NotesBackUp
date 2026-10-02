
["Standard Output"](https://en.wikipedia.org/wiki/Standard_streams#Standard_output_%28stdout%29), usually called "standard out" or "stdout", is the default place where programs print their output. It's just a stream of data that prints to your terminal, but we'll talk later about how it can be redirected to other places.

All programming languages have a simple way to print to stdout. In Python, it's the `print` function:

```py
print("Hello world")
# Hello world
```

In a shell, it's the `echo` command:

```bash
echo "Hello world"
# Hello world
```


---
**Standard Output (stdout)** is one of the three main data streams in Linux and programming:

|Stream|Name|Purpose|Default Target|
|---|---|---|---|
|`0`|**stdin**|Input to a program|Keyboard|
|`1`|**stdout**|Normal output|Terminal (screen)|
|`2`|**stderr**|Error messages|Terminal (screen)|

---

### 💡 What stdout is

It’s the **channel** where programs send their regular results.  
Example:

```bash
echo "Hello world"
```

This prints to **stdout** (stream `1`), which goes to your terminal by default.

---

### 🔀 Redirecting stdout

You can change where stdout goes.

|Action|Syntax|Meaning|
|---|---|---|
|Redirect to file|`>`|Overwrite file|
|Append to file|`>>`|Add to file|
|Explicitly reference stream|`1>`|Same as `>`|

Examples:

```bash
ls > files.txt      # save output
ls >> files.txt     # append
ls 1> files.txt     # same as above
```

---

### 🧩 Combine stdout & stderr

|Task|Syntax|Meaning|
|---|---|---|
|Redirect **both** stdout and stderr|`> out.txt 2>&1`|Both go to same file|
|Redirect only **stderr**|`2> errors.txt`|Errors only|

Example:

```bash
ls /root /tmp > all.txt 2> errors.txt
```

---

### 🧠 Check where stdout goes

Run:

```bash
ls > /dev/null
```

- `/dev/null` is the “black hole” — discards output completely.
    



##### Tags : [[2 - Tags/Linux|Linux]]