# Standard In

If there's a standard _output_, there must be a standard _input_, right?

["Standard Input"](https://en.wikipedia.org/wiki/Standard_streams#Standard_input_%28stdin%29), usually called "standard in" or "stdin", is the default place where programs _read_ their input. It's just a stream of data that programs can read from as they run.

All major programming languages provide a simple way to read from stdin. In Python, it's the `input` function:

```py
# execution stops until the user types
# something (in this case "Lane") and presses enter
name = input("What is your name? ")

print("Hello,", name)
# Hello, Lane!
```


---
**Standard Input (stdin)** — stream number **0** — is how a program **receives data** (usually from the keyboard, but it can come from files or other programs).



### 🧠 What stdin is

It’s the **input channel** of a process.  
By default:

- When you type something and press Enter → it’s sent to stdin.
    

Example:

```bash
cat
```

Now type:

```
hello
```

and press `Ctrl+D` (end of input).  
`cat` echoes what you typed — it read it from **stdin**.

---

### 🔀 Redirecting stdin from a file

You can make a program read from a file instead of the keyboard.

```bash
cat < file.txt
```

This means: “Take **stdin** from `file.txt`.”

---

### 🧩 Example with both redirections

```bash
sort < names.txt > sorted.txt
```

- `< names.txt` → input source (stdin)
    
- `> sorted.txt` → output target (stdout)
    

---

### 🧰 Piping (stdin + stdout)

You can send stdout of one command **as stdin** of another using `|`:

```bash
cat file.txt | grep "John"
```

Here:

- `cat file.txt` → writes to stdout
    
- `grep "John"` → reads that data via stdin
    

---

### 🕹️ Read stdin in a script

```bash
#!/bin/bash
echo "Enter your name:"
read name        # reads from stdin
echo "Hello, $name!"
```




##### Tags : [[2 - Tags/Linux|Linux]]