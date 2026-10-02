
A **shebang** (written `#!`) is the very first line in a script that tells the system **which interpreter** should run the file.

### 🔹 Syntax

```bash
#! /path/to/interpreter
```

### 🔹 Example

```bash
#!/bin/bash
echo "Hello, world!"
```

→ This means “run this script using **/bin/bash**.”

### 🔹 Common shebangs

|Purpose|Shebang line|
|---|---|
|Bash script|`#!/bin/bash`|
|POSIX shell|`#!/bin/sh`|
|Python script|`#!/usr/bin/env python3`|
|Perl script|`#!/usr/bin/perl`|
|Node.js script|`#!/usr/bin/env node`|

### 🔹 Why `#!/usr/bin/env python3`?

Because `env` finds the interpreter in your `PATH`. It’s **portable**—works even if Python is installed in a different directory.

### 🔹 Without shebang

If you run the script like this:

```bash
bash myscript.sh
```

it works, but the shell you specify (bash) is used.  
If you run it directly:

```bash
./myscript.sh
```

and **no shebang** is present, it may fail or use the current shell (which could be different).



##### Tags : [[2 - Tags/Linux|Linux]]