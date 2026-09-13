
> There are environment variables that are sort of "built-in" to your shell. By "built-in" I just mean that different programs and parts of your system know about them and use them. The `PATH` variable is one of those.

> If it weren't for the `PATH`, you'd have to remember the filesystem path of every executable you wanted to run in your shell. Instead of just running `ls`, you'd have to run `/bin/ls` (or whatever the location of the `ls` executable is on your system). That's not very convenient.

> The `PATH` variable is a list of directories that your shell will look into when you try to run a command. If you type `ls`, your shell will look in each directory listed in your `PATH` variable for an executable called `ls`. If it finds one, it will just run it. If it doesn't, it will give you an error like: "command not found".

---
## What's in the `PATH` Variable?

Take a look at your current `PATH` variable:

```bash
echo $PATH
```

You should see a giant list of directories separated by colons (`:`). Each of those directories is a place where your shell will look for executables. For example, with a `PATH` like this:

```
/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
```

Your shell will look for executables in the following directories:

- `/usr/local/bin`
- `/usr/bin`
- `/bin`
- `/usr/sbin`
- `/sbin`

----
`PATH` is an **environment variable** in Linux, macOS, and Windows that tells the shell **where to look for executable files** when you type a command.

### 🧠 In simple terms:

When you type a command like:

```bash
ls
```

the system doesn’t magically “know” what `ls` is — it searches for a file named `ls` in the directories listed in your `PATH`.

---

### ⚙️ Example

Run:

```bash
echo $PATH
```

You’ll see something like:

```
/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin
```

Each part separated by `:` is a **directory**.  
So when you type `ls`, the shell checks:

1. `/usr/local/bin/ls`
    
2. `/usr/bin/ls`
    
3. `/bin/ls`
    
4. `/usr/local/sbin/ls`
    
5. `/usr/sbin/ls`
    

— and runs the first one it finds.

---

### 🧩 How it works

- When you log in, your shell (like `bash` or `zsh`) loads configuration files (`~/.bashrc`, `~/.profile`, etc.) that set up the PATH.
    
- When you install a program (say, `java` or `python`), it usually adds its binary directory to PATH so you can run it from anywhere.
    

---

### 🛠️ Adding to PATH

You can temporarily add a directory:

```bash
export PATH=$PATH:/home/ethan/myprograms
```

Or permanently (add the above line to `~/.bashrc`).

Then any executable in `/home/ethan/myprograms` can be run directly by name.

---


Let’s trace exactly what happens when you type, say:

```bash
ls
```



### 🧩 Step-by-step PATH resolution

#### **1. You type the command**

You hit Enter after typing `ls`.

#### **2. The shell checks if it’s a built-in**

Your shell (like `bash` or `zsh`) first checks:

> “Is `ls` a built-in command?”  
> If yes, it runs it directly.  
> If not, it continues to the next step.

You can test this:

```bash
type ls
```

Example output:

```
ls is /bin/ls
```

---

#### **3. The shell looks through PATH**

The shell takes your `$PATH`, for example:

```
/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin
```

Then it searches **in order**:

1. `/usr/local/bin/ls`
    
2. `/usr/bin/ls`
    
3. `/bin/ls`
    
4. `/usr/local/sbin/ls`
    
5. `/usr/sbin/ls`
    

The first matching executable file it finds — it runs.

---

#### **4. It executes the binary**

Once found, the kernel loads that binary (e.g., `/bin/ls`) into memory and executes it as a process.

---

#### **5. If not found**

If the shell doesn’t find it in any PATH directory, you get:

```
bash: ls: command not found
```

---

### 🧠 Example experiment

Let’s say you have a script:

```bash
echo "Hello Ethan!"
```

Save it as `/home/ethan/scripts/hello`.

Make it executable:

```bash
chmod +x ~/scripts/hello
```

Now add it to PATH:

```bash
export PATH=$PATH:/home/ethan/scripts
```

Then you can run:

```bash
hello
```

from anywhere — no `./`, no path prefix.  
That’s exactly how Linux finds commands system-wide.

---




##### Tags : [[2 - Core-concepts/Linux|Linux]]