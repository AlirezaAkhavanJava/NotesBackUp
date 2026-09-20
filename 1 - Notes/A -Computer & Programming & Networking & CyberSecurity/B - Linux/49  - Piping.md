
# Piping

One of the most beautiful things about the shell is that you can [pipe](https://en.wikipedia.org/wiki/Pipeline_%28Unix%29) the output of one program into the input of another program. With this one simple concept, you can run incredibly powerful automation tasks.

## Pipe

The pipe operator is `|`. It's the character that looks like a vertical line. It's usually on the same key as the backslash (`\`) above the enter key. The pipe operator takes the stdout of the program on the left and "pipes" it into the stdin of the program on the right.

```bash
echo "Have you heard the tragedy of Darth Plagueis the Wise?" | wc -w
# 10
```

In the example above, the `echo` command sends "Have you heard the tragedy of Darth Plagueis the Wise?" to stdout.

However, instead of that text being sent to your terminal, the pipe operator pipes it into the `wc` (word count) command. The `wc` command counts the number of words in the input it receives. The `-w` flag tells `wc` to only count words.

This only works because the `wc` command, like most shell commands, can optionally read from stdin instead of a filepath.


----

**Piping (`|`)** in Linux connects the **stdout** of one command to the **stdin** of another — it’s how commands “talk” to each other.



### 🧠 Concept

When you use:

```bash
command1 | command2
```

…it means:

> Take whatever `command1` prints (stdout) and feed it as **input** (stdin) to `command2`.

---

### 🧩 Simple Example

```bash
ls | grep "txt"
```

- `ls` → lists files (stdout)
    
- `grep "txt"` → receives that list as stdin and filters only `.txt` files.
    

---

### 🧰 Common Uses

|Example|Description|
|---|---|
|`ps aux|grep java`|
|`cat file.txt|wc -l`|
|`dmesg|less`|
|`ls|sort`|
|`grep "error" log.txt|tee errors.txt`|

---

### 🔀 Combine with Redirection

You can mix pipes with stdout/stderr redirection:

```bash
ls /root 2>&1 | grep "Permission"
```

- `2>&1` merges stderr with stdout
    
- `grep` filters both together.
    

---

### ⚙️ Chain Multiple Pipes

```bash
cat access.log | grep "ERROR" | sort | uniq -c | sort -nr
```

Steps:

1. `cat` outputs file
    
2. `grep` filters “ERROR” lines
    
3. `sort` sorts them
    
4. `uniq -c` counts duplicates
    
5. `sort -nr` sorts numerically in reverse (most frequent first)
    



##### Tags : [[2 - Core-concepts/Linux|Linux]]