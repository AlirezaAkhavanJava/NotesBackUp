
### What is `grep`?

**grep** (Global Regular Expression Print) is one of the most powerful and fundamental command-line tools in Linux/Unix. Its primary purpose is to **search text or files for lines that match a given pattern**.

The name comes from the `ed` (the original Unix text editor) command `g/re/p` ( **g**lobally search for a **r**egular **e**xpression and **p**rint it).

---

### Basic Syntax

```bash
grep [OPTIONS] PATTERN [FILE...]
```

---

### 1. Common and Useful Options

Here are the most frequently used `grep` options:

| Option | Shorthand | Description |
| :--- | :--- | :--- |
| `--ignore-case` | `-i` | Makes the search case-insensitive. |
| `--invert-match` | `-v` | Shows lines that do **NOT** match the pattern. |
| `--recursive` | `-r` (or `-R`) | Search recursively through directories. |
| `--line-number` | `-n` | Prints the line number of matching lines. |
| `--count` | `-c` | Prints only the count of matching lines, not the lines themselves. |
| `--word-regexp` | `-w` | Searches for the pattern as a whole word. |
| `--fixed-strings` | `-F` | Treats the pattern as a literal string, not a regex. |
| `--color` | `--color=auto` | Highlights the matching pattern in color. |
| `--before-context=N` | `-B N` | Shows **N** lines **before** the match. |
| `--after-context=N` | `-A N` | Shows **N** lines **after** the match. |
| `--context=N` | `-C N` | Shows **N** lines **before and after** the match. |

---

### 2. Practical Examples

Let's assume we have a file called `fruits.txt` with the following content:

```
1 Apple
2 banana
3 Cherry
4 BANANA
5 apple pie
6 grape
```

#### Basic Search
```bash
# Search for the string "banana"
grep "banana" fruits.txt
# Output: 2 banana
```

#### Case-Insensitive Search (`-i`)
```bash
# Search for "apple", ignoring case
grep -i "apple" fruits.txt
# Output:
# 1 Apple
# 5 apple pie
```

#### Show Line Numbers (`-n`)
```bash
grep -n "banana" fruits.txt
# Output: 2:2 banana
```

#### Invert Match (`-v`)
```bash
# Show all lines that do NOT contain "banana"
grep -v "banana" fruits.txt
```

#### Count Matches (`-c`)
```bash
# Count how many times "apple" appears (case-sensitive)
grep -c "apple" fruits.txt
# Output: 1

# Count how many times "apple" appears (case-insensitive)
grep -ic "apple" fruits.txt
# Output: 2
```

#### Whole Word Search (`-w`)
```bash
# Search for the word "apple" as a whole word
grep -w "apple" fruits.txt
# Output: 5 apple pie

# Compare without -w (this would also match "pineapple")
grep "apple" fruits.txt
```

#### Search Recursively in Directories (`-r`)
```bash
# Search for the word "error" in all files in the /var/log directory
grep -r "error" /var/log/

# Same, but with line numbers and ignoring case
grep -rin "error" /var/log/
```

#### Show Context Around Matches (`-A`, `-B`, `-C`)
```bash
# Show the line containing "Cherry" and the next 2 lines after it
grep -A 2 "Cherry" fruits.txt

# Show the line containing "Cherry" and the 1 line before it
grep -B 1 "Cherry" fruits.txt

# Show the line containing "Cherry" and 1 line before and after
grep -C 1 "Cherry" fruits.txt
```

---

### 3. Using `grep` with Regular Expressions (Regex)

`grep` becomes incredibly powerful when combined with regex.

| Regex Symbol | Meaning | Example |
| :--- | :--- | :--- |
| `.` | Matches any single character. | `grep "a.p" file` (matches "app", "aap", "a3p") |
| `*` | Matches zero or more of the previous character. | `grep "a*ple" file` (matches "ple", "aple", "aaple") |
| `^` | Anchors the pattern to the start of a line. | `grep "^1" fruits.txt` (finds lines starting with "1") |
| `$` | Anchors the pattern to the end of a line. | `grep "pie$" fruits.txt` (finds lines ending with "pie") |
| `[ ]` | Matches any one of the characters inside the brackets. | `grep "[AC]" fruits.txt` (finds lines with 'A' or 'C') |
| `[^ ]` | Matches any character **NOT** in the brackets. | `grep "[^0-9]" fruits.txt` (finds lines with non-digits) |

**Regex Examples:**

```bash
# Find lines that start with a number
grep "^[0-9]" fruits.txt

# Find lines that end with a 'y'
grep "y$" fruits.txt

# Find lines containing 'a' followed by any character, followed by 'a'
grep "a.a" fruits.txt
# (This would match "banana" because of the 'a' at positions 2 and 4)
```

> **Pro Tip:** For more complex regex patterns (like `+`, `?`, `|`, `{}`), use **Extended Regular Expressions** with the `-E` flag or the `egrep` command.
> ```bash
> # Using -E to match "Apple" or "Banana"
> grep -E "Apple|Banana" fruits.txt
> # Using egrep (same as above)
> egrep "Apple|Banana" fruits.txt
> ```

---

### 4. Piping with `grep`

One of the most common uses of `grep` is to filter the output of other commands.

```bash
# Search for a running process
ps aux | grep "firefox"

# Check if a specific port is listening
netstat -tulpn | grep ":80"

# Search history for a specific command
history | grep "ssh"
```

---

### 5. Important Variants of `grep`

*   `egrep`: Equivalent to `grep -E` (uses Extended Regular Expressions).
*   `fgrep`: Equivalent to `grep -F` (fast, fixed-string search, no regex). Good for searching literal strings with special characters like `$`, `.`, `*`.
*   `rgrep`: Equivalent to `grep -r` (recursive search).

---

### Summary

`grep` is an indispensable tool for any Linux user. Start with the basic options like `-i`, `-n`, and `-v`, and then gradually incorporate recursion (`-r`) and regular expressions to unlock its full potential for searching and filtering text.
##### Tags : [[2 - Tags/Linux|Linux]]