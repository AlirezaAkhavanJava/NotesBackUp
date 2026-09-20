You're familiar with the idea of reading and writing data into files. But what about _executing_ them? Executable files are just files where the data stored inside is a program that you can run on your computer.

Files with a `.sh` extension are [shell scripts](https://en.wikipedia.org/wiki/Shell_script). They're just text files that contain shell commands. You can run a file in your shell by typing its filepath:

```bash
mydir/program.sh
```

Interestingly, if the program is in the current directory (in this example, the `mydir` directory), you need to prefix it with `./` to run it:

```bash
./program.sh
```

As far as file paths go, `./program.sh` and `program.sh` are the same. The dot (`.`) is an alias for the current directory. We _need_ the prefix when running executables so that the shell knows we're trying to run a file from a file path, not an installed command like `ls`, `mkdir`, `chmod`, etc.


#### Removing the permission to run the executable

```bash
chmod -x name.sh
```

*   This removes (`-`) the execute (`x`) permission for **everyone** (user, group, and others).
*   After this, no one can run the file as a program, even the owner.

#### Adding the permission to run the executable

```bash
chmod u+x <filename>
```


**1. `chmod u+x <filename>`** (as you mentioned)
*   This adds (`+`) execute (`x`) permission only for the **user**/owner (`u`).
*   The group and others still cannot execute it (unless they already had the permission).

**2. Other useful variations:**

```bash
# Add execute for everyone (user, group, and others)
chmod +x name.sh
# or equivalently:
chmod a+x name.sh

# Add execute for the group only
chmod g+x name.sh

# Add execute for others only
chmod o+x name.sh

# Add execute for both user and group
chmod ug+x name.sh
```

### Checking the Result:

After running any `chmod` command, you can verify the permissions with:
```bash
ls -l name.sh
```

**Example workflow:**
```bash
# 1. Create a script
echo '#!/bin/bash' > my_script.sh
echo 'echo "Hello World"' >> my_script.sh

# 2. Check initial permissions (probably no 'x')
ls -l my_script.sh
# -rw-r--r-- 1 user user 32 Mar 21 10:00 my_script.sh

# 3. Add execute permission for user only
chmod u+x my_script.sh

# 4. Verify the change
ls -l my_script.sh
# -rwxr--r-- 1 user user 32 Mar 21 10:00 my_script.sh
# Notice the 'x' now appears in the user section
```


---

> In simple terms, an **executable** is a file that contains a set of instructions (a program or a script) that the computer can **run** or **execute**.

> Think of it like a recipe. A text file with a recipe is just information. But if you give it to a chef (the computer), they can *execute* the instructions to create a meal (perform a task). The executable file is the recipe that the computer can understand and act upon.



### 1. It's Not About the File Extension

Unlike Windows (which uses `.exe`, `.msi`, etc.), Linux **does not rely on file extensions** to determine if a file is executable. A file called `backup` with no extension can be an executable, while a file called `notes.txt` could be one too (if given the right permissions).

Instead, Linux uses two main things:

*   **File Permissions:** Special "execute" permissions.
*   **File Content:** What's actually inside the file.

### 2. The "Execute" Permission

In Linux, every file has permissions for three types of users:
*   The **owner** of the file (`u`)
*   The **group** the file belongs to (`g`)
*   **All other** users (`o`)

For each of these, you can set three types of permissions:
*   **Read** (`r`): Can open and view the file's content.
*   **Write** (`w`): Can modify or delete the file.
*   **Execute** (`x`): Can run the file as a program.

You can see these permissions by using the `ls -l` command in the terminal.

**Example:**
```bash
ls -l /bin/ls
```
You might see an output like:
```
-rwxr-xr-x 1 root root 142144 Sep  5  2019 /bin/ls
```
The first part, `-rwxr-xr-x`, shows the permissions:
*   `-`: Indicates it's a regular file (a `d` would mean directory).
*   `rwx`: The **owner** (`root`) has **r**ead, **w**rite, and e**x**ecute.
*   `r-x`: The **group** has **r**ead and e**x**ecute (but not write).
*   `r-x`: **All others** have **r**ead and e**x**ecute.

The presence of those `x` letters is what tells the system "this file can be executed."

### 3. Types of Executables

There are two main kinds of executables you'll encounter:

**A. Binary Programs (Compiled)**
*   These are files written in languages like C or C++ that have been **compiled** directly into machine code that the processor understands.
*   They are not human-readable. If you opened one in a text editor, you'd see mostly gibberish and unprintable characters.
*   Examples: Commands like `ls`, `cp`, `grep`, and `firefox` are typically binary executables. They are usually located in directories like `/bin`, `/usr/bin`, `/sbin`.

**B. Scripts (Interpreted)**
*   These are plain text files that contain instructions for an **interpreter** (another program).
*   To be executable, they must meet two conditions:
    1.  Have the **execute permission** (as discussed above).
    2.  Specify **which interpreter** should run them on the very first line (this is called a **shebang**).

**The Shebang Line:**
The first line of a script must start with `#!` followed by the path to the interpreter.

*   **For a Bash script:** `#!/bin/bash`
*   **For a Python script:** `#!/usr/bin/env python3`

**Example of a simple Bash script:**
```bash
#!/bin/bash
# This is a comment. The line above is the shebang.
echo "Hello, World! The date is $(date)."
```
To turn this text file into an executable, you would save it (e.g., as `hello.sh`) and then run:
```bash
chmod +x hello.sh  # This adds the execute (+x) permission
./hello.sh         # This runs the script
```

### Summary: How to Make and Run Your Own Executable Script

1.  **Create the file:** `nano my_script`
2.  **Add the shebang and commands:**
    ```bash
    #!/bin/bash
    echo "I am learning Linux!"
    ```
3.  **Save and exit** (in `nano`, press `Ctrl+X`, then `Y`, then `Enter`).
4.  **Give it execute permission:** `chmod +x my_script`
5.  **Run it:** `./my_script`

The `./` is important. It tells the shell to look for the executable in the *current directory*. The system only looks in predefined directories (listed in the `$PATH` variable) for commands, so for your own scripts, you need to specify the path.

---

So, in a nutshell: **An executable is any file with the 'execute' permission set, which can be either a pre-compiled binary or a script that tells the system which interpreter to use.**



##### Tags : [[2 - Core-concepts/Linux|Linux]]