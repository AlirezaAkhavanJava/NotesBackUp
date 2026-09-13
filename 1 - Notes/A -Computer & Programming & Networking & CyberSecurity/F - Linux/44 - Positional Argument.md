
**Positional arguments** in Linux are the **values passed to a shell script or function**, and they’re accessed by their **position** (order) on the command line.

---

### 🧠 Concept

When you run a script like this:

```bash
./myscript.sh apple banana cherry
```

Inside the script:

- `$0` → script name (`./myscript.sh`)
    
- `$1` → first argument (`apple`)
    
- `$2` → second argument (`banana`)
    
- `$3` → third argument (`cherry`)
    

---

### 🧩 Example

```bash
#!/bin/bash
echo "Script name: $0"
echo "First arg: $1"
echo "Second arg: $2"
echo "Third arg: $3"
```

Run:

```bash
./test.sh red green blue
```

Output:

```
Script name: ./test.sh
First arg: red
Second arg: green
Third arg: blue
```

---

### 📦 Special Variables

|Variable|Meaning|
|---|---|
|`$#`|Number of positional arguments|
|`$@`|All arguments as separate words|
|`$*`|All arguments as a single word|
|`"$@"`|Expands each argument quoted separately (recommended)|
|`"$*"`|Expands all arguments as one string|
|`$?`|Exit status of the last command|
|`$$`|Process ID of the script|
|`$!`|PID of the last background process|

---

### 🧰 Example with Loop

```bash
#!/bin/bash
echo "Number of args: $#"
for arg in "$@"; do
  echo "Arg: $arg"
done
```

Run:

```bash
./args.sh one two three
```

Output:

```
Number of args: 3
Arg: one
Arg: two
Arg: three
```



##### Tags : [[2 - Core-concepts/Linux|Linux]]